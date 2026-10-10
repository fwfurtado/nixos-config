
{ pkgs, ... }:

{
  imports = [
    ../../modules
  ];

  networking.hostName = "nixos-test";
  boot.kernelParams = [ "console=ttyS0" ];

  users.mutableUsers = false;
  users.users.fernando = {
    isNormalUser = true;
    hashedPassword = "$6$nixostest$zYbTXkKr2RshAid5K9nha9HemsMiAZnclMsbtCPGfzFsKPft/A2x9aHI3iQhpcvSa5fx/OAmbXWmKavkxrRI1.";
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  security.sudo.wheelNeedsPassword = false;

  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
    forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        host.address = "127.0.0.1";
        guest.port = 22;
      }
    ];
  };

  system.stateVersion = "26.05";
}
