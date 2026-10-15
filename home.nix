{ system ? builtins.currentSystem, desktop ? false, homeUsername ? "fernando", tailnetProxy ? false }:
let
  inputs = import ./.tack;
  lib = inputs.nixpkgs.lib;

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "google-chrome" "slack" "obsidian" ];
  };

  homePlatform =
    if lib.hasSuffix "-darwin" system
    then "darwin"
    else "linux";
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

  extraSpecialArgs = {
    inherit inputs homePlatform homeUsername;
    homeTailnetProxy = tailnetProxy;
    standalone = true;
    homeDesktop = desktop;
    homeNoctaliaWallhavenSecretPath = null;
  };

  modules = [
    ./home/fernando
  ];
}
