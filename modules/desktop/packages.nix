{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        kitty

        wl-clipboard
        grim
        slurp
    ];
}
