{ config, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.sessionVariables = {
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
    ANDROID_SDK = "${home}/Library/Android/sdk";
  };

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/pkg/env/global/bin"
    "${home}/Library/Android/sdk/platform-tools"
  ];
}
