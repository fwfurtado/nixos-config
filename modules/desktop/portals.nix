{ pkgs, ... }:

{
    xdg.portal = {
        enable = true;

        extraPortals = [
            pkgs.xdg-desktop-portal-gtk
        ];

        config = {
            common = {
                default = [ "hyprland" "gtk" ];

                "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            };
        };
    };
}
