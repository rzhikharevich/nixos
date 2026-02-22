{ config, pkgs, ... }:
let
  powerMenu = pkgs.writeShellScript "power-menu" ''
    choice=$(echo -e 'Poweroff\nReboot\nCancel' | ${pkgs.fuzzel}/bin/fuzzel --dmenu \
      --line-height=40 \
      --minimal-lines \
      --background-color=0d1117ff \
      --text-color=c9d1d9ff \
      --selection-color=1f6febff \
      --selection-text-color=c9d1d9ff \
      --match-color=58a6ffff \
      --border-color=30363dff)
    case "$choice" in
      Poweroff) systemctl poweroff -i;;
      Reboot) systemctl reboot -i;;
      Cancel) true;;
    esac
  '';

  greeterWlgreetConfig = pkgs.writeText "greetd-wlgreet-config" ''
    command = "${pkgs.niri}/bin/niri"
    outputMode = "all"
    scale = 1

    [background]
    red = 0.051
    green = 0.067
    blue = 0.090
    opacity = 1.0

    [headline]
    red = 0.788
    green = 0.820
    blue = 0.851
    opacity = 1.0

    [prompt]
    red = 0.345
    green = 0.651
    blue = 1.0
    opacity = 1.0

    [promptErr]
    red = 0.973
    green = 0.318
    blue = 0.286
    opacity = 1.0

    [border]
    red = 0.188
    green = 0.212
    blue = 0.239
    opacity = 1.0
  '';

  greeterNiriConfig = pkgs.writeText "greetd-niri-config" ''
    output "eDP-1" {
      scale 2.0
    }

    cursor {
      xcursor-size 48
    }

    hotkey-overlay {
      skip-at-startup
    }
    spawn-at-startup "${pkgs.wvkbd}/bin/wvkbd-mobintl" "--hidden" "-L" "400" "--fn" "sans 20"
    spawn-at-startup "sh" "-c" "${pkgs.wlgreet}/bin/wlgreet --config ${greeterWlgreetConfig}; ${pkgs.niri}/bin/niri msg action quit --skip-confirmation"

    binds {
      XF86AudioRaiseVolume { spawn "pkill" "-SIGRTMIN" "wvkbd-mobintl"; }
      XF86AudioLowerVolume { spawn "${powerMenu}"; }
    }
  '';
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri --config ${greeterNiriConfig}";
        user = "greeter";
      };
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
           action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
           action.id == "org.freedesktop.login1.reboot-ignore-inhibit") &&
          subject.user == "greeter") {
        return polkit.Result.YES;
      }
    });
  '';

  security.pam.services.greetd.enableGnomeKeyring = true;
}
