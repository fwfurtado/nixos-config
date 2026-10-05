{ system ? builtins.currentSystem }:
let
  inputs = import ./.tack;
in
inputs.system-manager.lib.makeSystemConfig {
  modules = [
    ./standalone-system
    {
      nixpkgs.hostPlatform = system;
    }
  ];

  specialArgs = {
    inherit inputs;
  };
}
