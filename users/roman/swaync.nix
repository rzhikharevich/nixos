{ config, pkgs, lib, ... }:

{
  services.swaync = {
    enable = true;
    settings = {
      widgets = [ "buttons-grid" "dnd" "volume" "title" "notifications" ];

      widget-config.buttons-grid = let
        mkToggle = cond: then-cmd: else-cmd: "${pkgs.bash}/bin/sh -c '[[ ${cond} ]] && ${then-cmd} || ${else-cmd}'";
        mkState = cond: mkToggle cond "echo true" "echo false";
      in {
        actions = [
          {
            label = "Wi-Fi";
            type = "toggle";
            active = true;
            command = mkToggle "$SWAYNC_TOGGLE_STATE == true" "nmcli radio wifi on" "nmcli radio wifi off";
            update-command = mkState "$(nmcli radio wifi) == enabled";
          }
        ];
      };
    };
    style = ''
      .control-center {
        margin: 8px;
        border-radius: 16px;
        border: 1px solid rgba(255, 255, 255, 0.08);
      }

      .notification-row .notification {
        border-radius: 12px;
        margin: 4px 0;
      }
    '';
  };
}
