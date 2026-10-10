{ pkgs, ... }:
let
  sessionPackage = pkgs.runCommand "home-manager-niri-session" { } ''
    mkdir -p "$out/bin" "$out/share/wayland-sessions"

    cat > "$out/bin/start-home-manager-niri" <<'EOF'
    #!${pkgs.runtimeShell}
    set -eu

    if [ -z "''${HOME:-}" ]; then
      echo "HOME is not set; cannot locate the Home Manager profile" >&2
      exit 1
    fi

    launcher="$HOME/.nix-profile/bin/niri-session"
    if [ ! -x "$launcher" ]; then
      echo "Niri launcher not found at $launcher" >&2
      echo "Run 'make home-switch-desktop' for this user first." >&2
      exit 1
    fi

    export PATH="$HOME/.nix-profile/bin:$PATH"
    export XDG_DATA_DIRS="$HOME/.nix-profile/share:/run/system-manager/sw/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

    exec "$launcher"
    EOF
    chmod +x "$out/bin/start-home-manager-niri"

    cat > "$out/share/wayland-sessions/niri-home-manager.desktop" <<EOF
    [Desktop Entry]
    Name=Niri (Home Manager)
    Comment=Niri managed by Home Manager
    Exec=/run/system-manager/sw/bin/start-home-manager-niri
    Type=Application
    DesktopNames=niri
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
