{ config, pkgs, lib, ... }:
let
  colloidIcons = pkgs.colloid-icon-theme.override { colorVariants = ["grey"]; };
  keyboardIcon = pkgs.prerenderIcon {
    name = "keyboard-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/actions/24/input-keyboard-virtual-show.svg";
  };
  overviewIcon = pkgs.prerenderIcon {
    name = "overview-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/actions/24/preferences-activities.svg";
  };
  notificationsIcon = pkgs.prerenderIcon {
    name = "notifications-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/status/24/notification-active.svg";
  };
  maximizeIcon = pkgs.prerenderIcon {
    name = "maximize-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/actions/24/view-fullscreen.svg";
  };
  volumeIcon = pkgs.prerenderIcon {
    name = "volume-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/status/24/audio-volume-high-panel.svg";
  };
  volumeMutedIcon = pkgs.prerenderIcon {
    name = "volume-muted-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/status/24/audio-volume-muted-panel.svg";
  };
  batteryIcon = pkgs.prerenderIcon {
    name = "battery-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/status/24/battery-good.svg";
  };
  batteryChargingIcon = pkgs.prerenderIcon {
    name = "battery-charging-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/status/24/battery-full-charging.svg";
  };
  fuzzelIcon = pkgs.prerenderIcon {
    name = "fuzzel-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/actions/24/search.svg";
  };
  iconButtonStyle = icon: ''
    background-image: url("${icon}");
    background-size: contain;
    background-repeat: no-repeat;
    background-position: center;
    min-width: 40px;
    padding: 0 12px;
  '';
  iconModuleStyle = icon: ''
    background-image: url("${icon}");
    background-size: 24px;
    background-repeat: no-repeat;
    background-position: left center;
    padding-left: 28px;
  '';
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      height = 40;
      margin-top = 4;
      margin-left = 8;
      margin-right = 8;
      modules-left = [ "custom/fuzzel" "custom/overview" "custom/maximize" "niri/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "niri/language" "wireplumber" "upower" "custom/keyboard" "custom/notifications" ];
      "custom/fuzzel" = {
        format = " ";
        tooltip-format = "Launch application";
        on-click = "${pkgs.fuzzel}/bin/fuzzel";
      };
      "custom/overview" = {
        format = " ";
        tooltip-format = "Toggle overview";
        on-click = "${pkgs.niri}/bin/niri msg action toggle-overview";
      };
      "custom/maximize" = {
        format = " ";
        tooltip-format = "Toggle maximize column";
        on-click = "${pkgs.niri}/bin/niri msg action maximize-column";
      };
      "custom/notifications" = {
        format = " ";
        tooltip-format = "Toggle notification center";
        on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t";
      };
      "custom/keyboard" = {
        format = " ";
        tooltip-format = "Toggle on-screen keyboard";
        on-click = "pkill -SIGRTMIN wvkbd-deskintl";
      };
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

      #custom-fuzzel,
      #custom-overview,
      #custom-maximize,
      #custom-notifications,
      #custom-keyboard {
        background-size: contain;
        background-repeat: no-repeat;
        background-position: center;
        min-width: 64px;
        margin: 3px 3px;
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

      #custom-keyboard {
        background-image: url("${keyboardIcon}");
      }

      #workspaces button {
        margin: 3px 3px;
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

      #wireplumber,
      #battery {
        min-width: 24px;
      }

      #wireplumber {
        ${iconModuleStyle volumeIcon}
      }

      #wireplumber.muted {
        ${iconModuleStyle volumeMutedIcon}
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
