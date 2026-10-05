{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "pre-home-manager";

    extraSpecialArgs = {
      inherit inputs;
    };

    users.fernando = import ../home/fernando;
  };
}
