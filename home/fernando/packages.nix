{ pkgs, ... }:
{
  # Cross-platform packages without a useful Home Manager module.
  home.packages = with pkgs; [
    sd
    mise
    jq
  ];
}
