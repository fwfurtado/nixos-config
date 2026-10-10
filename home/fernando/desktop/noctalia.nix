{ config, inputs, lib, homeNoctaliaWallhavenSecretPath ? null, ... }:
let
  isMinipc = homeNoctaliaWallhavenSecretPath != null;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = lib.recursiveUpdate {
      shell = {
        polkit_agent = true;
        launch_apps_as_systemd_services = true;
      };

      # Location lookup via noctalia.dev supplies the sunrise/sunset schedule.
      location.auto_locate = true;
      nightlight.enabled = true;

      # Noctalia owns session locking and monitor power management.
      idle.behavior = {
        screen-off = {
          timeout = 600;
          action = "screen_off";
        };
        lock = {
          timeout = 900;
          action = "lock";
        };
      };
    } (lib.optionalAttrs isMinipc (builtins.fromTOML (builtins.readFile ./noctalia-settings.toml)));
  };

  # The source is a symlink to sops-nix's runtime path, never a Nix store copy.
  xdg.configFile."noctalia/zz-wallhaven-secret.toml" = lib.mkIf isMinipc {
    source = config.lib.file.mkOutOfStoreSymlink homeNoctaliaWallhavenSecretPath;
  };
}
