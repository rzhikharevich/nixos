{ config, osConfig, lib, pkgs, ... }:
let graphicalSessionUnit = {
  PartOf = "graphical-session.target";
  After = "graphical-session.target";
};
in {
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
        backdrop-color = "000000";
      };
    };

    cursor.hide-when-typing = true;

    binds = {
      "Super+L".action.spawn = [ "${pkgs.systemd}/bin/systemctl" "--user" "start" "hyprlock" ];
      "Super+T".action.spawn = [ "${pkgs.foot}/bin/foot" ];
      "Super+D".action.spawn = [ "${pkgs.fuzzel}/bin/fuzzel" ];
      "Super+Q".action.close-window = [];
      "Super+Shift+E".action.quit = [];
      "Super+F".action.toggle-window-floating = [];
      "Super+Left".action.focus-column-left = [];
      "Super+Right".action.focus-column-right = [];
      "Super+Up".action.focus-window-or-workspace-up = [];
      "Super+Down".action.focus-window-or-workspace-down = [];
    };

    window-rules =
      let uniformCornerRadius = (r: lib.genAttrs
        [ "bottom-left" "bottom-right" "top-left" "top-right" ]
        (_: r)
      );
      in [
        {
          clip-to-geometry = true;
        }
        {
          matches = [ { is-floating = true; } ];
          shadow.enable = true;
        }

        {
          matches = [ {
            app-id = "firefox";
            title = "Picture-in-Picture";
          } ];

          open-floating = true;
          open-focused = false;
          border.enable = false;
          shadow.enable = true;

          default-floating-position = {
            x = 48;
            y = 48;
            relative-to="bottom-right";
          };
          max-height = 360;
          min-height = 360;
          max-width = 640;
          min-width = 576;
        }

        # Adjusting for app-specific corner radii.
        # TODO: Maybe there's a way to tell apps to not have rounded corners?
        # TODO: Alternatively, could just go with rounding everything.
        {
          matches = [ { app-id = "firefox"; } ];
          excludes = [ { title = "Picture-in-Picture"; } ];
          geometry-corner-radius = uniformCornerRadius 14.0;
        }
        {
          matches = [ { app-id = "dev.zed.Zed"; } ];
          geometry-corner-radius = uniformCornerRadius 10.0;
        }
      ];
  };

  systemd.user.services.hyprlock = {
    Unit = {
      Description = "Lock screen";
      Before = "user-sleep.target";
    } // graphicalSessionUnit;
    Service = {
      ExecStartPre = "${pkgs.niri}/bin/niri msg action do-screen-transition --delay-ms 100";
      ExecStart = "${pkgs.hyprlock}/bin/hyprlock";
      ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
      Restart = "on-failure";
    };
    Install.RequiredBy = [ "user-sleep.target" ];
  };

  systemd.user.services.niri-monitor-power-manager = {
    Unit = {
      Description = "Niri monitor power manager";
      Before = "user-sleep.target";
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      ExecStop = "${pkgs.niri}/bin/niri msg action power-on-monitors";
    };
    Install.WantedBy = [ "user-sleep.target" ];
  };

  systemd.user.services.wvkbd = {
    Unit = {
      Description = "On-screen keyboard";
    } // graphicalSessionUnit;
    Service = {
      ExecStart = "${pkgs.wvkbd}/bin/wvkbd-deskintl --hidden -L 500 --fn \"sans 20\"";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.swaybg = {
    Unit = {
      Description = "Desktop background";
    } // graphicalSessionUnit;
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i ${config.stylix.image}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
