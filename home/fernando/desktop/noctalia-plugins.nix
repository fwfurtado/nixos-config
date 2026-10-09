{ config, pkgs, lib, homeNoctaliaWallhavenSecretPath ? null, ... }:
let
  isMinipc = homeNoctaliaWallhavenSecretPath != null;
  depthPython = pkgs.python3.withPackages (pythonPackages: with pythonPackages; [
    numpy
    onnxruntime
    pillow
  ]);
  officialPlugins = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "official-plugins";
    rev = "d097eb5e197f5714bef80b2185cdf60bb4b8aae8";
    hash = "sha256-KRUfwrIHBIVf0l+dNtCkTQqZAHgHAkC8e75tUpiQxrk=";
  };

  communityPlugins = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "community-plugins";
    rev = "795a3f1d8b11501bbd89684f56e2e9905233665d";
    hash = "sha256-BaPBFNgjmSMITMJxMgthEwf+NZj/3R7HEm8ce94kKrY=";
  };
in
{
  programs.noctalia.settings.plugins = lib.mkIf isMinipc {
    # Enabled IDs and widgets are declared in noctalia-settings.toml.
    auto_update = "none";
    source = [
      {
        name = "official";
        kind = "path";
        location = "${officialPlugins}";
        enabled = true;
      }
      {
        name = "community";
        kind = "path";
        location = "${communityPlugins}";
        enabled = true;
      }
    ];
  };

  # Wallpaper Depth runs python3 directly; its ONNX dependencies must be
  # available to the Noctalia user service without a plugin-managed venv.
  home.packages = lib.optionals isMinipc [ depthPython ];
  systemd.user.services.noctalia.Service.Environment = lib.mkIf isMinipc [
    "PATH=${lib.makeBinPath [ depthPython ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
  ];
}
