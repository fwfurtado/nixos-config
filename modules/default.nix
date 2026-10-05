{ ... }:
{
  imports = [
    ./desktop
    ./secrets
    ./services
    ./home-manager.nix
    ./audio.nix
    ./base.nix
    ./bluetooth.nix
    ./keyboard.nix
    ./networking.nix
    ./power.nix
    ./users.nix
  ];
}
