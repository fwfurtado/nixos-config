
{ ... }:

{
  imports = [
    ../../modules/base.nix
    ../../modules/users.nix
    ../../modules/packages.nix
    ../../modules/networking.nix
    ../../modules/desktop
  ];

  networking.hostName = "nixos-test";

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
