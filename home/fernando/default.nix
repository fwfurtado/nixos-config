{ ... }:
{
  imports = [
    ./environment.nix
    ./packages.nix
    ./programs
    ./desktop
    ./services
  ];

  home = {
    username = "fernando";
    homeDirectory = "/home/fernando";
    stateVersion = "26.05";
    preferXdgDirectories = true;
  };

  programs.home-manager.enable = true;
}
