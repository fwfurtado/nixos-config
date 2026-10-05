{ pkgs, ... }:
{
  imports = [
    ./desktop
    ./services
  ];

  home.packages = with pkgs; [
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

  programs.neovim.extraPackages = with pkgs; [
    wl-clipboard
  ];

  programs.fish.functions = {
    pbcopy.body = builtins.readFile ./programs/fish-functions/pbcopy.fish;
    pbpaste.body = builtins.readFile ./programs/fish-functions/pbpaste.fish;
  };

  programs.ghostty = {
    systemd.enable = true;

    settings = {
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
