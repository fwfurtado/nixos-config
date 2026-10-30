{ config, pkgs, ... }:
let
  sdk = pkgs.callPackage ../../packages/obsbot-sdk.nix { };
  relay = pkgs.callPackage ../../packages/tiny-virtual-camera.nix { obsbotSdk = sdk; };
  camera = "/dev/v4l/by-id/usb-Remo_Tech_Co.__Ltd._OBSBOT_Tiny_3_Lite-video-index0";
in
{
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=42 card_label="Tiny 3 Lite Virtual" exclusive_caps=1
  '';

  home-manager.users.fwfurtado.systemd.user.services.tiny-virtual-camera = {
    Unit = {
      Description = "Virtual Tiny 3 Lite with on-demand physical capture";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${relay}/bin/tiny-virtual-camera /dev/video42 ${camera} ${pkgs.ffmpeg}/bin/ffmpeg";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
