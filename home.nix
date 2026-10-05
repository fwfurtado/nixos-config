{ system ? builtins.currentSystem }:
let
  inputs = import ./.tack;

  pkgs = import inputs.nixpkgs {
    inherit system;
  };
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

  extraSpecialArgs = {
    inherit inputs;
    standalone = true;
  };

  modules = [
    ./home/fernando
  ];
}
