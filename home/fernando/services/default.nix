{ lib, homeTailnetProxy ? false, ... }:
{
  imports = [
    ./easyeffects.nix
  ] ++ lib.optionals homeTailnetProxy [
    ./proxy.nix
  ];
}
