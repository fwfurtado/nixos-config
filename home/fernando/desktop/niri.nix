{ pkgs, standalone ? false, ... }:
{
  wayland.windowManager.niri = {
    enable = true;
    # NixOS installs the session and user unit system-wide. A standalone
    # Home Manager desktop supplies the same niri-session from its profile.
    systemd.enable = standalone;
    portalPackage = if standalone then pkgs.xdg-desktop-portal-gnome else null;
    extraConfig = builtins.readFile ./niri/config.kdl;
  };

  # The system Niri module owns these portals on NixOS; standalone needs both.
  xdg.portal.extraPortals = if standalone then [ pkgs.xdg-desktop-portal-gtk ] else [ ];
}
