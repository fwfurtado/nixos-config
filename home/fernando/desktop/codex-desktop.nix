{ lib, pkgs, homeUsername, standalone, ... }:
{
  # The upstream wrapper enables native Wayland only when both variables exist.
  # Set Ozone for this application, not for every Electron application.
  home.packages = lib.optionals (standalone || homeUsername == "fwfurtado") [
    (pkgs.symlinkJoin {
      name = "chatgpt-wayland";
      paths = [ pkgs.chatgpt ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/chatgpt --set NIXOS_OZONE_WL 1
      '';
    })
  ];
}
