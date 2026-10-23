{ pkgs, ... }:
{
  users.groups.git = { };
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = "/var/lib/git";
    createHome = true;
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = [
      # Public signing key from home/fernando/programs/git.nix; push is allowed.
      "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnjxWt9XUWWnP0ilRlAugrqYs0RKgfzn/3ZiyEKEENo"
      "restrict,command=\"git-upload-pack '/var/lib/git/cluster.git'\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHGKFsh+0mtgf9IL7Q9HoGIZvU2HvVnPKRvQkwDJx2/A flux@fw-minipc"
    ];
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      AllowUsers = [ "git" ];
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      DisableForwarding = true;
      PermitTTY = false;
    };
  };

  # Local pushes use loopback; k3s pods reach SSH through the cni0 bridge.
  # Do not open port 22 on the LAN interface.
  networking.firewall.interfaces.cni0.allowedTCPPorts = [ 22 ];

  systemd.services.git-bare-repository = {
    description = "Initialize the local GitOps bare repository";
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "!/var/lib/git/cluster.git/HEAD";
    serviceConfig = {
      Type = "oneshot";
      User = "git";
      Group = "git";
      StateDirectory = "git";
      StateDirectoryMode = "0700";
      ExecStart = "${pkgs.git}/bin/git init --bare --initial-branch=main /var/lib/git/cluster.git";
    };
  };
}
