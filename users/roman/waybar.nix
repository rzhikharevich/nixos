{ config, pkgs, lib, ... }:
let
  colloidIcons = pkgs.colloid-icon-theme.override { colorVariants = ["grey"]; };
  keyboardIcon = pkgs.prerenderIcon {
    name = "keyboard-icon.png";
    src = "${colloidIcons}/share/icons/Colloid-Grey-Dark/actions/24/input-keyboard-virtual-show.svg";
  };
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      height = 44;
      modules-left = [ "niri/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "custom/keyboard" "niri/language" "wireplumber" "battery" ];
      "custom/keyboard" = {
        format = " ";
        tooltip-format = "Toggle on-screen keyboard";
        on-click = "pkill -SIGRTMIN wvkbd-deskintl";
      };
    };
    style = ''
      window#waybar {
        background-color: alpha(@base00, 0.85);
      }

      #custom-keyboard {
        background-image: url("${keyboardIcon}");
        background-size: contain;
        background-repeat: no-repeat;
        background-position: center;
        min-width: 24px;
        padding: 0 8px;
      }

      #workspaces button {
        margin: 4px 4px;
        background-color: @base02;
        opacity: 0.85;
        box-shadow: 0 0 2px 0px black;
      }

      #workspaces button.active {
        background-color: @base0D;
        color: @base00;
      }

      .modules-left #workspaces button.active {
          border: 0;
      }
    '';
  };
}
