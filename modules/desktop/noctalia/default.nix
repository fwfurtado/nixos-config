{ ... }:
{
  # The shell itself is user state and is configured by Home Manager.
  # The greeter exists before login, so it stays on the NixOS side.
  imports = [
    ./greeter.nix
  ];
}
