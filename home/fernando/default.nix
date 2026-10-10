{ lib, homePlatform, homeDesktop ? false, homeUsername ? "fernando", ... }:
{
  imports = [
    ./common.nix
  ]
  ++ lib.optionals (homePlatform == "linux") [
    ./linux.nix
  ]
  ++ lib.optionals (homePlatform == "linux" && homeDesktop) [
    ./linux-desktop.nix
  ]
  ++ lib.optionals (homePlatform == "darwin") [
    ./darwin.nix
  ];

  home = {
    username = homeUsername;
    homeDirectory =
      if homePlatform == "darwin"
      then "/Users/${homeUsername}"
      else "/home/${homeUsername}";

    stateVersion = "26.05";
    preferXdgDirectories = true;
  };

  programs.home-manager.enable = true;
}
