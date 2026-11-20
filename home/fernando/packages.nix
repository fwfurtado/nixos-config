{ lib, pkgs, homePlatform, homeDesktop ? false, ... }:
{
  # Cross-platform packages without a useful Home Manager module.
  home.packages = with pkgs; [
    sd
    mise
    mergiraf
    ec
    hunk
    bat-extras.batman
    bat-extras.batpipe
    jq
    rtk
    dbeaver-bin
    databricks-cli
    krew
    (gitbutler.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.oniguruma pkgs.sqlite ];
    }))
    teleport
  ] ++ lib.optionals (homePlatform == "linux" && homeDesktop) [
    pkgs.tuios
  ];
}
