{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        ghostty

        wl-clipboard
        grim
        slurp

        networkmanagerapplet
        blueman
    ];
}
