{ ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Hyprlock is configured in Home Manager, but PAM is a system concern.
  security.pam.services.hyprlock = { };
}
