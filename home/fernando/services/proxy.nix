{ config, inputs, lib, pkgs, standalone ? false, homeProxyUserSecretPath ? null, ... }:
let
  agentSocket = "${config.home.homeDirectory}/.1password/agent.sock";
  secretPath =
    if standalone
    then config.sops.secrets."vpn-proxy-user".path
    else homeProxyUserSecretPath;
in
{
  imports = lib.optionals standalone [
    inputs.sops-nix.homeManagerModules.sops
    ({ config, ... }: {
      sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      sops.secrets."vpn-proxy-user" = {
        sopsFile = ../../../secrets/vpn-proxy-user.enc;
        format = "binary";
      };
    })
  ];

  home.sessionVariables.SSH_AUTH_SOCK = agentSocket;

  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.settings."*" = {
    IdentityAgent = agentSocket;
    ForwardAgent = false;
    AddKeysToAgent = "no";
    Compression = false;
    ServerAliveInterval = 0;
    ServerAliveCountMax = 3;
    HashKnownHosts = false;
    UserKnownHostsFile = "~/.ssh/known_hosts";
    ControlMaster = "no";
    ControlPath = "~/.ssh/master-%r@%n:%p";
    ControlPersist = "no";
  };
  programs.ssh.settings."vpn-proxy" = {
    HostName = "192.168.10.234";
    Include = secretPath;
    DynamicForward = "127.0.0.1:1080";
    ServerAliveInterval = 15;
    ServerAliveCountMax = 3;
    ExitOnForwardFailure = "yes";
    IdentityAgent = agentSocket;
    # Export the *public* key of the dedicated tunnel key from 1Password here.
    IdentityFile = "${config.home.homeDirectory}/.ssh/vpn-proxy.pub";
    IdentitiesOnly = "yes";
  };

  systemd.user.services.vpn-proxy = {
    Unit = {
      Description = "SOCKS proxy for the tailnet via Mac";
      After = [ "network-online.target" ] ++ lib.optionals standalone [ "sops-nix.service" ];
      Requires = lib.optionals standalone [ "sops-nix.service" ];
    };
    Service = {
      Environment = [
        "AUTOSSH_GATETIME=0"
        "SSH_AUTH_SOCK=${agentSocket}"
      ];
      ExecStartPre = "${pkgs.coreutils}/bin/test -r ${secretPath}";
      ExecStart = "${pkgs.autossh}/bin/autossh -M 0 -N vpn-proxy";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
