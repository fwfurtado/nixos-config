{ pkgs, ... }:
{
  # Packages without a useful Home Manager module, or packages used directly
  # by Hyprland bindings/services.
  home.packages = with pkgs; [
    sd
    mise
    jq

    wl-clipboard
    grim
    slurp
    swappy
    cliphist
    playerctl
    brightnessctl
    fuzzel
    nautilus
  ];
}
