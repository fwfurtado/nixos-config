{ inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      # Keep Noctalia's runtime defaults for now; future UI changes belong here.
      # This is intentionally a Nix attrset, not a linked TOML file.
      launch_apps_as_systemd_services = true;
    };
  };
}
