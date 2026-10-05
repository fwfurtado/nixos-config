{ lib, pkgs, ... }:
{
  imports = [
    ./common.nix
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    ./linux.nix
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    ./darwin.nix
  ];

  home = {
    username = "fernando";
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/fernando"
      else "/home/fernando";

    stateVersion = "26.05";
    preferXdgDirectories = true;
  };

  programs.home-manager.enable = true;
}
