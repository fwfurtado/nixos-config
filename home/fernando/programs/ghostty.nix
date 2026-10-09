{ lib, pkgs, homePlatform, homeDesktop ? false, ... }:
{
  programs.ghostty = {
    enable = true;
    # nixpkgs does not package Ghostty for Darwin; manage its config here and
    # use the native macOS application installation instead.
    package = if homePlatform == "darwin" then null else pkgs.ghostty;
    enableFishIntegration = true;

    settings = {
      "mouse-scroll-multiplier" = 1;
      "background-blur" = 10;
      theme =
        if homePlatform == "linux" && homeDesktop then "noctalia" else "Ubuntu";
      "background-opacity" =
        if homePlatform == "linux" && homeDesktop then 0.95 else 0.3;
      "font-size" = 18;

      keybind = [
        ''alt+backspace=text:\x1b\x7f''
      ];
    } // lib.optionalAttrs (homePlatform == "linux" && homeDesktop) {
      # The graphical ChezMoi profile starts tuios in new Ghostty windows.
      "initial-command" = "tuios";
    };
  };
}
