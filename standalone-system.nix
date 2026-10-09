{ system ? builtins.currentSystem }:
let
  # Tack owns the exact revision. Native Nix resolves this upstream flake's
  # nested userborn follows; Tack's transitive resolver recurses on that graph.
  systemManagerRevision = (builtins.fromJSON (builtins.readFile ./.tack/pins.lock.json)).system-manager.rev;
  systemManager = builtins.getFlake "github:numtide/system-manager/${systemManagerRevision}";
in
systemManager.lib.makeSystemConfig {
  modules = [
    ./standalone-system
    {
      nixpkgs.hostPlatform = system;
    }
  ];

}
