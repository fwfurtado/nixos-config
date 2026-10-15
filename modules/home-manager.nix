{ config, inputs, homeUsername ? "fernando", homeTailnetProxy ? false, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "pre-home-manager";

    extraSpecialArgs = {
      inherit inputs homeUsername homeTailnetProxy;
      standalone = false;
      homePlatform = "linux";
      homeProxyUserSecretPath =
        if homeTailnetProxy then config.sops.secrets."vpn-proxy-user".path else null;
      homeNoctaliaWallhavenSecretPath =
        if config.sops.secrets ? "noctalia-wallhaven"
        then config.sops.secrets."noctalia-wallhaven".path
        else null;
      homeDesktop = true;
    };

    users.${homeUsername} = import ../home/fernando;
  };
}
