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
      "Super+L".action.spawn = [ "${pkgs.systemd}/bin/systemctl" "--user" "start" "swaylock" ];
      "Super+T".action.spawn = [ "${pkgs.foot}/bin/foot" ];
      "Super+Q".action.close-window = [];
      "Super+Shift+E".action.quit = [];
      "Super+F".action.toggle-window-floating = [];
    };

    window-rules = [
      {
        matches = [
          {
            is-floating = true;
          }
        ];
        shadow.enable = true;
      }
    ];
  };

  programs.swaylock.enable = true;
  # Don't want a swaylock crash expose the session :)
  systemd.user.services.swaylock = {
    Unit = {
      Description = "Lock screen";
    } // graphicalSessionUnit;
    Service = {
      ExecStart = "${pkgs.swaylock}/bin/swaylock";
      Restart = "on-failure";
    };
  };

  systemd.user.services.swaybg = {
    Unit = {
      Description = "Desktop background";
    } // graphicalSessionUnit;
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i ${config.stylix.image}";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
