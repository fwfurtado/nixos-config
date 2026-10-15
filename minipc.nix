let
  inputs = import ./.tack;
in
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  specialArgs = {
    inherit inputs;
    homeTailnetProxy = true;
    homeUsername = "fwfurtado";
  };

  modules = [
    ./hosts/minipc
  ];
}
