{ ... }:
{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    systemd.enable = true;

    settings = {
      "mouse-scroll-multiplier" = 1;
      "background-blur" = 10;
      theme = "Ubuntu";
      "background-opacity" = 0.3;
      "font-size" = 18;

      keybind = [
        ''alt+backspace=text:\x1b\x7f''
        "global:super+ctrl+grave_accent=toggle_quick_terminal"
      ];

      "quit-after-last-window-closed" = false;
      "quick-terminal-position" = "top";
      "quick-terminal-size" = "40%,40%";
      "gtk-quick-terminal-layer" = "overlay";
      "quick-terminal-keyboard-interactivity" = "on-demand";
      "quick-terminal-autohide" = true;
    };
  };
}
