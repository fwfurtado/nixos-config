{ pkgs, ... }:
{
  # programs.niri supplies the niri-specific GNOME screencast portal and
  # portal routing; GTK handles access, notifications and fallback dialogs.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
