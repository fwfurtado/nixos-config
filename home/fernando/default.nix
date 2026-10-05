{ lib, homePlatform, ... }:
{
  imports = [
    ./common.nix
  ]
  ++ lib.optionals (homePlatform == "linux") [
    ./linux.nix
  ]
  ++ lib.optionals (homePlatform == "darwin") [
    ./darwin.nix
  ];

  home = {
    username = "fernando";
    homeDirectory =
      if homePlatform == "darwin"
      then "/Users/fernando"
      else "/home/fernando";

    stateVersion = "26.05";
    preferXdgDirectories = true;
  };

  programs.home-manager.enable = true;
}
