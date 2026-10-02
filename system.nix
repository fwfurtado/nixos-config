let
  inputs = import ./.tack;
in
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  modules = [
    ./hosts/vm
  ];
}
