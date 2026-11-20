{ inputs, ... }:
{
  # Home Manager shares the system package set (useGlobalPkgs).
  nixpkgs.overlays = [ (import ../../overlays/codex-desktop.nix { inherit inputs; }) ];
}
