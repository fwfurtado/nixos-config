let
  inputs = import ../.tack;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  relay = pkgs.callPackage ../packages/tiny-virtual-camera.nix {
    controlsSource = ./obsbot-controls-fake.cpp;
  };
  cameraSource = pkgs.writeShellScript "virtual-camera-test-source" ''
    echo "$$" > /run/tiny-camera-source.pid
    if [ -e /run/tiny-camera-emit-frame ]; then
      ${pkgs.coreutils}/bin/dd if=/dev/zero bs=1382400 count=1 status=none
    fi
    exec ${pkgs.coreutils}/bin/sleep 3600
  '';
in
pkgs.testers.runNixOSTest {
  name = "tiny-virtual-camera";
  nodes.machine = { config, ... }: {
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=42 card_label="Tiny 3 Lite Virtual" exclusive_caps=1
    '';
    environment.systemPackages = [ pkgs.v4l-utils pkgs.python3 ];
    systemd.services.tiny-virtual-camera = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${relay}/bin/tiny-virtual-camera /dev/video42 /dev/nonexistent ${cameraSource}";
        Restart = "on-failure";
      };
    };
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("tiny-virtual-camera.service")
    machine.wait_until_succeeds("v4l2-ctl -d /dev/video42 --info | grep 'Video Capture'")
    machine.succeed("test ! -e /run/tiny-camera-source.pid")
    machine.succeed("systemd-run --unit=tiny-consumer --collect -- v4l2-ctl -d /dev/video42 --stream-mmap --stream-count=1000000 --stream-to=/dev/null")
    machine.wait_until_succeeds("test -f /run/tiny-camera-source.pid && kill -0 $(cat /run/tiny-camera-source.pid)")
    machine.succeed("systemctl stop tiny-consumer.service")
    machine.wait_until_succeeds("! kill -0 $(cat /run/tiny-camera-source.pid)")
    machine.succeed("timeout 15 v4l2-ctl -d /dev/video42 --stream-mmap --stream-count=1 --stream-to=/tmp/idle.yuv")
    machine.succeed("python3 -c 'data = open(\"/tmp/idle.yuv\", \"rb\").read(); assert len(data) == 1280*720*3//2; assert data[:1280*720] == bytes([16]) * (1280*720); assert data[1280*720:] == bytes([128]) * (1280*720//2)'")
    machine.succeed("systemctl is-active tiny-virtual-camera.service")
    machine.succeed("timeout 15 v4l2-ctl -d /dev/video42 --stream-mmap --stream-count=1 --stream-to=/tmp/idle-again.yuv")
    machine.succeed("touch /run/tiny-camera-emit-frame")
    machine.succeed("systemd-run --unit=tiny-sdk-consumer --collect -- v4l2-ctl -d /dev/video42 --stream-mmap --stream-count=1000000 --stream-to=/dev/null")
    machine.wait_until_succeeds("grep -q '^active$' /run/tiny-camera-sdk-events")
    machine.succeed("! grep -q '^sleep$' /run/tiny-camera-sdk-events")
    machine.succeed("systemctl stop tiny-sdk-consumer.service")
    machine.wait_until_succeeds("grep -q '^sleep$' /run/tiny-camera-sdk-events")
    machine.succeed("systemd-run --unit=tiny-sdk-consumer-again --collect -- v4l2-ctl -d /dev/video42 --stream-mmap --stream-count=1000000 --stream-to=/dev/null")
    machine.wait_until_succeeds("test $(grep -c '^active$' /run/tiny-camera-sdk-events) -ge 2")
    machine.succeed("test $(grep -c '^sleep$' /run/tiny-camera-sdk-events) -eq 1")
    machine.succeed("systemctl stop tiny-sdk-consumer-again.service")
    machine.wait_until_succeeds("test $(grep -c '^sleep$' /run/tiny-camera-sdk-events) -ge 2")
  '';
}
