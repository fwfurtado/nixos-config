{ ... }:
{
  imports = [
    ./desktop
    ./secrets
    ./home-manager.nix
    ./audio.nix
    ./bluetooth.nix
    ./keyboard.nix
    ./networking.nix
    ./power.nix
    ./users.nix
  ];
}
