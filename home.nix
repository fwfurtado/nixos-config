{ system ? builtins.currentSystem, desktop ? false }:
let
  inputs = import ./.tack;
  lib = inputs.nixpkgs.lib;

  pkgs = import inputs.nixpkgs {
    inherit system;
  };

  homePlatform =
    if lib.hasSuffix "-darwin" system
    then "darwin"
    else "linux";
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

  extraSpecialArgs = {
    inherit inputs homePlatform;
    standalone = true;
    homeDesktop = desktop;
  };

  modules = [
    ./home/fernando
  ];
}
