{ lib, homeTailnetProxy ? false, ... }:
{
  imports = lib.optionals homeTailnetProxy [
    ./proxy.nix
  ];
}
