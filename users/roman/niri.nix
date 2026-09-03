{
  config,
  lib,
  pkgs,
  ...
}:
let
  graphicalSessionUnit = {
    PartOf = "graphical-session.target";
    After = "graphical-session.target";
  };
  uniformCornerRadius =
    r: lib.genAttrs [ "bottom-left" "bottom-right" "top-left" "top-right" ] (_: r);
  mkAlpha = color: alpha: "#${color}${lib.trivial.toHexString (builtins.floor (alpha * 255))}";
  mkTiledShadow = color: {
    enable = true;
    softness = 12;
    spread = 2;
    offset = {
      x = 0.0;
      y = 4.0;
    };
    color = color;
  };
  mkFloatingShadow = color: {
    enable = true;
    softness = 25;
    spread = 5;
    offset = {
      x = 0.0;
      y = 4.0;
    };
    color = color;
  };
in
{
  programs.niri.settings = {
    input = {
      keyboard.xkb = {
        layout = "us,ru";
        options = "grp:win_space_toggle";
      };

      focus-follows-mouse.enable = true;
      mouse.accel-profile = "flat";

      touchpad = {
        tap = true;
        dwt = true;
        natural-scroll = true;
        click-method = "clickfinger";
      };

      touch.map-to-output = "eDP-1";
    };

    outputs = {
      "eDP-1" = {
        scale = 1.5;
        variable-refresh-rate = true;
        backdrop-color = config.lib.stylix.colors.base00;
      };
    };

    cursor.hide-when-typing = true;

    hotkey-overlay.skip-at-startup = true;

    animations = {
      workspace-switch.kind.spring = {
        damping-ratio = 0.9;
        stiffness = 800;
        epsilon = 0.0001;
      };
      horizontal-view-movement.kind.spring = {
        damping-ratio = 0.9;
        stiffness = 800;
        epsilon = 0.0001;
      };
      window-open.kind.easing = {
        duration-ms = 200;
        curve = "ease-out-expo";
      };
      window-close.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-quad";
      };
      window-movement.kind.spring = {
        damping-ratio = 0.9;
        stiffness = 600;
        epsilon = 0.0001;
      };
      window-resize.kind.spring = {
        damping-ratio = 0.9;
        stiffness = 600;
        epsilon = 0.0001;
      };
    };

    binds = {
      "Super+B".action.spawn = [
        (
          lib.toString
          <| pkgs.writeShellScript "toggle-waybar" ''
            if ${lib.getExe' pkgs.systemd "systemctl"} --user is-active waybar.service; then
              ${lib.getExe' pkgs.systemd "systemctl"} --user stop waybar.service
            else
              ${lib.getExe' pkgs.systemd "systemctl"} --user start waybar.service
            fi
          ''
        )
      ];
      "Super+Q".action.close-window = [ ];
      "Super+A".action.toggle-overview = [ ];
      "Super+S".action.spawn = [
        "${pkgs.swaynotificationcenter}/bin/swaync-client"
        "-t"
      ];
      "Ctrl+Space".action.spawn = [ "${pkgs.toggleUserUnit "fuzzel"}" ];
      "Super+F".action.toggle-column-tabbed-display = [ ];
      "Super+M".action.maximize-column = [ ];
      "Super+L".action.spawn = [
        "${pkgs.systemd}/bin/systemctl"
        "--user"
        "start"
        "hyprlock"
      ];
      "Super+Shift+E".action.quit = [ ];
      "Super+T".action.toggle-window-floating = [ ];
      "Super+Left".action.focus-column-left = [ ];
      "Super+Right".action.focus-column-right = [ ];
      "Super+Up".action.focus-window-or-workspace-up = [ ];
      "Super+Down".action.focus-window-or-workspace-down = [ ];
      "Ctrl+Super+Left".action.consume-or-expel-window-left = [ ];
      "Ctrl+Super+Right".action.consume-or-expel-window-right = [ ];
      "XF86AudioRaiseVolume".action.spawn = [
        "${pkgs.brightnessctl}/bin/brightnessctl"
        "set"
        "5%+"
      ];
      "XF86AudioLowerVolume".action.spawn = [
        "${pkgs.brightnessctl}/bin/brightnessctl"
        "set"
        "5%-"
      ];
    }
    // lib.listToAttrs (
      map (i: {
        name = "Super+${toString i}";
        value.action.focus-workspace = i;
      }) (lib.range 1 5)
    );

    layout = {
      always-center-single-column = true;

      tab-indicator = {
        place-within-column = true;
        length.total-proportion = 0.95;
        gaps-between-tabs = 10.0;
        position = "left";
        corner-radius = 10.0;
        width = 10.0;
      };
    };

    window-rules = [
      {
        clip-to-geometry = true;
        geometry-corner-radius = uniformCornerRadius 12.0;
        shadow = (mkTiledShadow <| mkAlpha config.lib.stylix.colors.base0D 0.4) // {
          inactive-color = (mkAlpha config.lib.stylix.colors.base03 0.4);
        };
        border.width = 2;
      }

      {
        matches = [ { is-floating = true; } ];
        shadow = mkFloatingShadow (mkAlpha config.lib.stylix.colors.base0D 0.3) // {
          inactive-color = mkAlpha config.lib.stylix.colors.base03 0.3;
        };
      }

      {
        matches = [ { app-id = "firefox"; } ];
        excludes = [ { title = "Picture-in-Picture"; } ];
        geometry-corner-radius = uniformCornerRadius 14.0;
      }

      {
        matches = [
          {
            app-id = "firefox";
            title = "Picture-in-Picture";
          }
        ];

        open-floating = true;
        open-focused = false;
        border.enable = false;
        geometry-corner-radius = uniformCornerRadius 0.0;

        default-floating-position = {
          x = 48;
          y = 48;
          relative-to = "bottom-right";
        };
        max-height = 360;
        min-height = 360;
        max-width = 640;
        min-width = 576;
      }
    ];

    layer-rules = [
      {
        matches = [ { namespace = "waybar"; } ];
        shadow = mkTiledShadow <| mkAlpha config.lib.stylix.colors.base00 0.6;
        geometry-corner-radius = uniformCornerRadius 12.0;
      }

      {
        matches = [ { namespace = "wvkbd"; } ];
        shadow = {
          enable = true;
          softness = 20;
          spread = 4;
          offset = {
            x = 0.0;
            y = -4.0;
          };
          color = mkAlpha "000000" 0.4;
        };
      }
    ];
  };

  # systemd.user.services.niri-monitor-power-manager = {
  #   Unit = {
  #     Description = "Niri monitor power manager";
  #     Before = "user-sleep.target";
  #   };
  #   Service = {
  #     Type = "oneshot";
  #     RemainAfterExit = "yes";
  #     ExecStart = "${pkgs.niri}/bin/niri msg action power-off-monitors";
  #     ExecStop = "${pkgs.niri}/bin/niri msg action power-on-monitors";
  #   };
  #   Install.WantedBy = [ "user-sleep.target" ];
  # };

  systemd.user.services.wvkbd = {
    Unit = {
      Description = "On-screen keyboard";
    }
    // graphicalSessionUnit;
    Service = {
      ExecStart = "${pkgs.wvkbd}/bin/wvkbd-deskintl --hidden -L 500 --fn \"sans 20\"";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.fuzzel = {
    Unit = {
      Description = "Application launcher";
    }
    // graphicalSessionUnit;
    Service = {
      ExecStart = "${pkgs.fuzzel}/bin/fuzzel";
    };
  };

  systemd.user.services.swaybg = {
    Unit = {
      Description = "Desktop background";
    }
    // graphicalSessionUnit;
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i ${config.stylix.image}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
