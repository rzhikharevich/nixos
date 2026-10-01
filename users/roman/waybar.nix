{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) mkColloidIcon;
  keyboardIcon = mkColloidIcon "keyboard-icon" "actions/24/input-keyboard-virtual-show.svg";
  overviewIcon = mkColloidIcon "overview-icon" "actions/24/preferences-activities.svg";
  notificationsIcon = mkColloidIcon "notifications-icon" "status/24/notification-active.svg";
  maximizeIcon = mkColloidIcon "maximize-icon" "actions/24/view-fullscreen.svg";
  volumeIcon = mkColloidIcon "volume-icon" "status/24/audio-volume-high-panel.svg";
  volumeMutedIcon = mkColloidIcon "volume-muted-icon" "status/24/audio-volume-muted-panel.svg";
  fuzzelIcon = mkColloidIcon "fuzzel-icon" "actions/24/search.svg";
  rotateIcon = mkColloidIcon "rotate-icon" "actions/24/screen-rotate-auto-on.svg";
  rotateScript = pkgs.writeShellScript "toggle-rotation" ''
    ${pkgs.niri}/bin/niri msg action do-screen-transition
    current=$(${pkgs.niri}/bin/niri msg --json focused-output | ${pkgs.jq}/bin/jq -r '.logical.transform')
    if [ "$current" = "Normal" ]; then
      ${pkgs.niri}/bin/niri msg output ${osConfig.rzhikharevich.touchDisplay} transform 90
    else
      ${pkgs.niri}/bin/niri msg output ${osConfig.rzhikharevich.touchDisplay} transform normal
    fi
  '';
  touchOnly = x: if osConfig.rzhikharevich.touchDisplay != null then x else null;
  touchOnlyString = s: if osConfig.rzhikharevich.touchDisplay != null then s else "";
  mkCustomButton = tooltip: command: {
    format = " ";
    tooltip-format = tooltip;
    on-click = command;
  };
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      height = 40;
      margin-top = 4;
      margin-left = 8;
      margin-right = 8;
      modules-left = [
        "custom/overview"
        "custom/maximize"
        "niri/workspaces"
      ];
      modules-center = [ "clock" ];
      modules-right = lib.rzSkipNulls [
        "niri/language"
        "wireplumber"
        "upower"
        (touchOnly "custom/rotate")
        (touchOnly "custom/keyboard")
        "custom/notifications"
        "custom/fuzzel"
      ];
      "custom/fuzzel" = mkCustomButton "Toggle app launcher" "${pkgs.toggleUserUnit "fuzzel"}";
      "custom/overview" =
        mkCustomButton "Toggle overview" "${pkgs.niri}/bin/niri msg action toggle-overview";
      "custom/maximize" =
        mkCustomButton "Toggle maximize column" "${pkgs.niri}/bin/niri msg action maximize-column";
      "custom/notifications" =
        mkCustomButton "Toggle notification center" "${pkgs.swaynotificationcenter}/bin/swaync-client -t";
      "niri/language" = {
        "format-en" = "🇺🇸";
        "format-ru" = "🇷🇺";
      };
      wireplumber = {
        format = "{volume}%";
        format-muted = "";
      };
      upower = {
        format = " {percentage}";
        format-charging = " {percentage}";
      };
    }
    // lib.optionalAttrs (osConfig.rzhikharevich.touchDisplay != null) {
      "custom/rotate" = mkCustomButton "Toggle screen rotation" "${rotateScript}";
      "custom/keyboard" = mkCustomButton "Toggle on-screen keyboard" "pkill -SIGRTMIN wvkbd-deskintl";
    };
    style = ''
      * {
        font-feature-settings: "tnum";
        font-family: sans-serif;
        font-weight: bold;
        color: @base05;
      }

      window#waybar {
        background-color: alpha(@base00, 0.7);
        background-image: linear-gradient(to bottom, alpha(white, 0.05), transparent 50%);
        background-clip: padding-box;
        border-radius: 12px;
      }

      #clock {
        font-size: 24px;
      }

      ${touchOnlyString ''
        #custom-keyboard,
        #custom-rotate,
      ''}
      #custom-fuzzel,
      #custom-overview,
      #custom-maximize,
      #custom-notifications {
        background-size: contain;
        background-repeat: no-repeat;
        background-position: center;
        min-width: 64px;
        margin: 3px;
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
        background-color: alpha(@base01, 0.9);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.3);
      }

      #custom-fuzzel {
        background-image: url("${fuzzelIcon}");
      }

      #custom-overview {
        background-image: url("${overviewIcon}");
      }

      #custom-maximize {
        background-image: url("${maximizeIcon}");
      }

      #custom-notifications {
        background-image: url("${notificationsIcon}");
      }

      ${touchOnlyString ''
        #custom-keyboard {
          background-image: url("${keyboardIcon}");
        }

        #custom-rotate {
          background-image: url("${rotateIcon}");
        }
      ''}

      #workspaces button {
        margin: 3px;
        min-width: 40px;
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
        background-image: radial-gradient(ellipse at 50% 30%, alpha(white, 0.08), transparent 70%);
        background-color: alpha(@base01, 0.3);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.4);
      }

      #workspaces button.active {
        background-image: radial-gradient(ellipse at 50% 30%, alpha(white, 0.14), transparent 70%);
        background-color: alpha(@base02, 0.9);
        border: 1px solid alpha(white, 0.1);
      }

      #workspaces button.urgent {
        background-image: radial-gradient(ellipse at 50% 30%, alpha(white, 0.12), transparent 70%);
        background-color: alpha(@base08, 0.9);
        color: @base00;
        border: 1px solid alpha(@base08, 0.4);
      }

      #wireplumber {
        min-width: 24px;
        background-image: url("${volumeIcon}");
        background-size: 24px;
        background-repeat: no-repeat;
        background-position: left center;
        padding-left: 28px;
      }

      #wireplumber.muted {
        background-image: url("${volumeMutedIcon}");
        padding-left: 0;
      }

      label.module,
      box.module {
        margin: 0 3px;
      }
    '';
  };
  stylix.targets.waybar.addCss = false;
}
