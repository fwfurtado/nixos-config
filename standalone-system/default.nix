{ lib, pkgs, ... }:
let
  sessionPackage = pkgs.runCommand "home-manager-hyprland-session" { } ''
    mkdir -p "$out/bin" "$out/share/wayland-sessions"

    cat > "$out/bin/start-home-manager-hyprland" <<'EOF'
    #!${pkgs.runtimeShell}
    set -eu

    if [ -z "''${HOME:-}" ]; then
      echo "HOME is not set; cannot locate the Home Manager profile" >&2
      exit 1
    fi

    launcher="$HOME/.nix-profile/bin/start-hyprland"
    if [ ! -x "$launcher" ]; then
      echo "Hyprland launcher not found at $launcher" >&2
      echo "Run 'make home-switch-desktop' for this user first." >&2
      exit 1
    fi

    exec "$launcher"
    EOF
    chmod +x "$out/bin/start-home-manager-hyprland"

    cat > "$out/share/wayland-sessions/hyprland-home-manager.desktop" <<EOF
    [Desktop Entry]
    Name=Hyprland (Home Manager)
    Comment=Hyprland managed by Home Manager
    Exec=/run/system-manager/sw/bin/start-home-manager-hyprland
    Type=Application
    DesktopNames=Hyprland
    EOF
  '';

  greetdWrapper = pkgs.writeShellScript "greetd-host" ''
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    exec greetd --config /etc/greetd/config.toml
  '';
in
{
  # Ubuntu/Debian are supported by System Manager. Fedora is currently
  # best-effort upstream, so allow it explicitly for this cross-distro profile.
  system-manager.allowAnyDistro = true;

  # Nix itself is installed and maintained outside System Manager on the
  # standalone hosts. Avoid taking ownership of /etc/nix/nix.conf.
  nix.enable = false;

  environment.systemPackages = [
    sessionPackage
  ];

  environment.etc = {
    "greetd/config.toml" = {
      replaceExisting = true;
      text = ''
        [terminal]
        vt = 1

        [default_session]
        command = "${pkgs.coreutils}/bin/env PATH=/usr/local/bin:/usr/bin:/bin XDG_DATA_DIRS=/run/system-manager/sw/share:/usr/local/share:/usr/share noctalia-greeter-session"
        user = "greeter"
      '';
    };
  };

  # The distro package supplies greetd's PAM integration and the greeter user.
  # System Manager owns the service definition/enablement after bootstrap.
  systemd.services.greetd = {
    enable = true;
    description = "greetd display manager";
    after = [
      "systemd-user-sessions.service"
      "plymouth-quit-wait.service"
    ];
    wants = [
      "systemd-user-sessions.service"
    ];
    conflicts = [
      "getty@tty1.service"
    ];
    wantedBy = [
      "graphical.target"
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${greetdWrapper}";
      Restart = "always";
      RestartSec = "1s";
      IgnoreSIGPIPE = false;
      SendSIGHUP = true;
      TimeoutStopSec = "30s";
      KeyringMode = "shared";
    };
  };
}
