{ config, inputs, lib, pkgs, standalone ? false, homeProxyUserSecretPath ? null, ... }:
let
  agentSocket = "${config.home.homeDirectory}/.1password/agent.sock";
  secretPath =
    if standalone
    then config.sops.secrets."vpn-proxy-user".path
    else homeProxyUserSecretPath;
  checkProxy = pkgs.writeShellScript "check-vpn-proxy" ''
    set -eu

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/vpn-proxy"
    state_file="$state_dir/health"
    mkdir -p "$state_dir"

    state=unknown
    if [ -r "$state_file" ]; then
      IFS= read -r state < "$state_file" || :
    fi

    notify() {
      echo "vpn-proxy-health: $1"
      ${pkgs.libnotify}/bin/notify-send "VPN proxy" "$1" || :
    }

    if ${pkgs.curl}/bin/curl --disable \
        --proxy socks5h://127.0.0.1:1080 \
        --connect-timeout 3 --max-time 10 \
        --fail --silent --show-error --output /dev/null \
        https://example.com/ 2>/dev/null
    then
      if [ "$state" = down ]; then
        notify "Proxy voltou a funcionar"
      fi
      if [ "$state" != healthy ]; then
        printf '%s\n' healthy > "$state_file"
      fi
    else
      case "$state" in
        unknown|healthy) next=failed-1 ;;
        failed-1)       next=failed-2 ;;
        *)              next=down ;;
      esac

      if [ "$next" = down ] && [ "$state" != down ]; then
        notify "Proxy indisponível"
      fi
      if [ "$state" != "$next" ]; then
        printf '%s\n' "$next" > "$state_file"
      fi
    fi
  '';
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
        "AUTOSSH_POLL=60"
        "SSH_AUTH_SOCK=${agentSocket}"
      ];
      ExecStartPre = "${pkgs.coreutils}/bin/test -r ${secretPath}";
      ExecStart = "${pkgs.autossh}/bin/autossh -M 20000 -N vpn-proxy";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.vpn-proxy-health = {
    Unit.Description = "Check VPN proxy reachability";
    Service = {
      Type = "oneshot";
      ExecStart = "${checkProxy}";
    };
  };

  systemd.user.timers.vpn-proxy-health = {
    Unit.Description = "Periodically check VPN proxy";
    Timer = {
      OnStartupSec = "1min";
      OnUnitActiveSec = "1min";
      Unit = "vpn-proxy-health.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
