{ config, standalone ? false, ... }:
let
  home = config.home.homeDirectory;
in
{
  targets.genericLinux.enable = standalone;
  home.sessionVariables.ANDROID_SDK = "${home}/Android/Sdk";

  home.sessionPath = [
    "${home}/Android/Sdk/platform-tools"
    "${home}/Android/Sdk/tools/bin"
    "${home}/Android/Sdk/tools"
  ];

  programs.fish.functions.pi-seccomp-off.body =
    builtins.readFile ./programs/fish-functions/pi-seccomp-off.fish;
}
