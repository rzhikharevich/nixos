{ config, pkgs, lib, ... }:

{
  services.swaync = {
    enable = true;
    settings = {
      widgets = [ "buttons-grid" "dnd" "volume" "notifications" ];

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
        box-shadow: 0 0 8px 0 rgba(0, 0, 0, 0.8);
      }
    '';
  };
}
