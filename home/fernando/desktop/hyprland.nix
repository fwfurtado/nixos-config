{ ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;

    # NixOS owns the compositor/session packages; Home Manager owns user config.
    package = null;
    portalPackage = null;
    configType = "lua";

    # UWSM owns the session lifecycle, so do not start a second HM session target.
    systemd.enable = false;

    settings = {
      config = {
        general = {
          layout = "master";
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          col = {
            active_border = "rgba(7fb4c9ff)";
            inactive_border = "rgba(2a2f3aff)";
          };
          resize_on_border = true;
          allow_tearing = false;
        };

        master = {
          new_status = "slave";
          new_on_top = false;
          mfact = 0.42;
          orientation = "center";
          slave_count_for_center_master = 1;
        };

        decoration = {
          rounding = 8;
          active_opacity = 1.0;
          inactive_opacity = 0.96;
          blur = {
            enabled = true;
            size = 6;
            passes = 2;
            new_optimizations = true;
            popups = true;
          };
          shadow = {
            enabled = false;
            range = 18;
            render_power = 2;
            color = "rgba(00000055)";
          };
        };

        animations.enabled = true;

        input = {
          kb_layout = "us";
          kb_variant = "mac";
          kb_model = "pc105";
          kb_options = "lv3:ralt_switch";
          repeat_rate = 40;
          repeat_delay = 300;
          follow_mouse = 1;
          sensitivity = 0.4;
          accel_profile = "adaptive";
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            clickfinger_behavior = true;
          };
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
          vrr = 0;
          focus_on_activate = true;
          middle_click_paste = false;
        };

        debug.vfr = true;

        cursor = {
          no_hardware_cursors = false;
          inactive_timeout = 5;
        };
      };

      curve = [
        {
          _args = [
            "snap"
            {
              type = "bezier";
              points = [ [ 0.2 0.9 ] [ 0.3 1.0 ] ];
            }
          ];
        }
        {
          _args = [
            "ease"
            {
              type = "bezier";
              points = [ [ 0.25 0.1 ] [ 0.25 1.0 ] ];
            }
          ];
        }
      ];

      animation = [
        { leaf = "windows"; enabled = true; speed = 3; bezier = "snap"; style = "popin 92%"; }
        { leaf = "windowsOut"; enabled = true; speed = 3; bezier = "snap"; style = "popin 92%"; }
        { leaf = "border"; enabled = true; speed = 6; bezier = "ease"; }
        { leaf = "fade"; enabled = true; speed = 3; bezier = "ease"; }
        { leaf = "workspaces"; enabled = true; speed = 3; bezier = "snap"; style = "slidefade 15%"; }
        { leaf = "layers"; enabled = true; speed = 3; bezier = "snap"; style = "fade"; }
      ];

      gesture = {
        fingers = 3;
        direction = "horizontal";
        scale = 0.5;
        action = "workspace";
      };

      env = [
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
        { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
        { _args = [ "QT_QPA_PLATFORM" "wayland;xcb" ]; }
        { _args = [ "QT_QPA_PLATFORMTHEME" "qt6ct" ]; }
        { _args = [ "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1" ]; }
        { _args = [ "QT_AUTO_SCREEN_SCALE_FACTOR" "1" ]; }
        { _args = [ "GDK_BACKEND" "wayland,x11" ]; }
        { _args = [ "SDL_VIDEODRIVER" "wayland" ]; }
        { _args = [ "CLUTTER_BACKEND" "wayland" ]; }
        { _args = [ "MOZ_ENABLE_WAYLAND" "1" ]; }
        { _args = [ "ELECTRON_OZONE_PLATFORM_HINT" "auto" ]; }
        { _args = [ "XCURSOR_THEME" "Adwaita" ]; }
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "HYPRCURSOR_THEME" "Adwaita" ]; }
        { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
        { _args = [ "GTK_IM_MODULE" "gtk-im-context-simple" ]; }
        { _args = [ "QT_IM_MODULE" "compose" ]; }
        { _args = [ "XMODIFIERS" "@im=none" ]; }
      ];

      monitor = [
        {
          output = "DP-1";
          mode = "5120x1440@120.00";
          position = "0x0";
          scale = 1;
        }
      ];

      workspace_rule = [
        { workspace = "1"; monitor = "DP-1"; default = true; persistent = true; }
        { workspace = "2"; monitor = "DP-1"; persistent = true; }
        { workspace = "3"; monitor = "DP-1"; persistent = true; }
        { workspace = "4"; monitor = "DP-1"; persistent = true; }
        { workspace = "5"; monitor = "DP-1"; persistent = true; }
        { workspace = "6"; monitor = "DP-1"; }
        { workspace = "7"; monitor = "DP-1"; }
        { workspace = "8"; monitor = "DP-1"; }
        { workspace = "9"; monitor = "DP-1"; }
        { workspace = "9"; gaps_out = 10; }
      ];

      window_rule = [
        { match.class = "^(xdg-desktop-portal-hyprland|hyprland-share-picker)$"; float = true; center = true; stay_focused = true; pin = true; no_anim = true; }
        { match.title = "^(.*is sharing.*)$"; no_screen_share = true; }
        { match.title = "^(Open File|Save File|Save As|Abrir|Salvar como)$"; float = true; center = true; }
        { match.class = "^(pavucontrol|org.pulseaudio.pavucontrol)$"; float = true; center = true; size = [ 1200 800 ]; }
        { match.class = "^(blueman-manager)$"; float = true; center = true; size = [ 1200 800 ]; }
        { match.class = "^(nm-connection-editor)$"; float = true; center = true; }
        { match.class = "^(hyprpolkitagent|polkit-gnome-authentication-agent-1)$"; float = true; center = true; }
        { match.class = "^(code|Code|code-url-handler)$"; workspace = "2"; }
        { match.class = "^(code|Code)$"; idle_inhibit = "focus"; }
        { match.class = "^(Slack|discord|vesktop)$"; workspace = "9"; }
        { match.class = "^(zoom)$"; workspace = "9"; }
        { match.class = "^(zoom|firefox|chromium|google-chrome)$"; idle_inhibit = "fullscreen"; }
        { match.title = "^(.*Meet.*|.*Zoom Meeting.*)$"; idle_inhibit = "focus"; }
        { match.title = "^(Picture-in-Picture|Picture in picture)$"; float = true; pin = true; size = [ 640 360 ]; move = [ "100%-680" "100%-420" ]; }
        { match.workspace = "special:scratch"; float = true; center = true; size = [ 2000 1200 ]; }
      ];

      layer_rule = [
        { match.namespace = "launcher"; blur = true; }
      ];
    };

    # This file contains real Lua control flow/callbacks; keeping it as code is
    # preferable to encoding Lua expressions as strings in Nix.
    extraLuaFiles.binds = {
      content = ./hyprland/binds.lua;
      autoLoad = true;
    };

    xdph.settings.screencopy = {
      allow_token_by_default = true;
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "loginctl lock-session";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        no_fade_in = false;
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
          noise = 0.011;
          contrast = 0.9;
          brightness = 0.6;
          vibrancy = 0.17;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "420, 60";
          outline_thickness = 2;
          dots_size = 0.28;
          dots_spacing = 0.3;
          dots_center = true;
          outer_color = "rgba(7fb4c9cc)";
          inner_color = "rgba(12141aee)";
          font_color = "rgba(c8cdd8ff)";
          fade_on_empty = false;
          placeholder_text = ''<span foreground="##6b7385">senha</span>'';
          fail_text = ''<span foreground="##d1735b">$FAIL ($ATTEMPTS)</span>'';
          position = "0, -80";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = ''cmd[update:1000] date +"%H:%M"'';
          color = "rgba(c8cdd8ff)";
          font_size = 96;
          font_family = "JetBrains Mono ExtraBold";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:60000] date +"%A, %d de %B"'';
          color = "rgba(6b7385ff)";
          font_size = 18;
          font_family = "JetBrains Mono";
          position = "0, 40";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
