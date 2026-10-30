{ lib, pkgs, ... }:
{
  imports = [
    ../../modules
    ../../modules/services/system/sing-box.nix
    ./storage.nix
    ./secrets.nix
    ./software.nix
    ./git-ssh.nix
    ./virtual-camera.nix
  ];

  networking.hostName = "fw-minipc";
  time.timeZone = "America/Sao_Paulo";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.pki.certificateFiles = [ ./home-arpa-ca.crt ];

  # No copy of the VM's known password or passwordless wheel policy.
  users.users.fwfurtado = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.fish;
  };
  # Only appearance-only greeter sync is passwordless for this local login;
  # other administrative actions still require authorization.
  services.displayManager.noctalia-greeter.passwordlessSyncUsers = [ "fwfurtado" ];

  virtualisation.docker.enable = true;

  # Keep the global inbound port list empty; git-ssh.nix opens only cni0.
  networking.firewall.allowedTCPPorts = lib.mkForce [ ];

  # K3s single-node
  services.k3s = {
      enable = true;
      role = "server";
  };

  system.stateVersion = "26.05";
}
