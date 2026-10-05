{ ... }:
{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      "mouse-scroll-multiplier" = 1;
      "background-blur" = 10;
      theme = "Ubuntu";
      "background-opacity" = 0.3;
      "font-size" = 18;

      keybind = [
        ''alt+backspace=text:\x1b\x7f''
      ];
    };
  };
}
