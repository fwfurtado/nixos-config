{ lib, pkgs, ... }:
{
  imports = [
    ../../modules
    ../../modules/services/system/sing-box.nix
    ./storage.nix
    ./secrets.nix
    ./software.nix
  ];

  networking.hostName = "fw-minipc";
  time.timeZone = "America/Sao_Paulo";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # No copy of the VM's known password or passwordless wheel policy.
  users.users.fwfurtado = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };
  # Only appearance-only greeter sync is passwordless for this local login;
  # other administrative actions still require authorization.
  services.displayManager.noctalia-greeter.passwordlessSyncUsers = [ "fwfurtado" ];

  # Only outgoing SSH is needed by the SOCKS tunnel.
  services.openssh.enable = false;
  networking.firewall.allowedTCPPorts = lib.mkForce [ ];

  system.stateVersion = "26.05";
}
