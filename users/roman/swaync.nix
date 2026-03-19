{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.swaync = {
    enable = true;
    settings = {
      widgets = [
        "buttons-grid"
        "dnd"
        "volume"
        "title"
        "notifications"
      ];

      widget-config.buttons-grid =
        let
          mkToggle =
            cond: then-cmd: else-cmd:
            "${pkgs.bash}/bin/sh -c '[[ ${cond} ]] && ${then-cmd} || ${else-cmd}'";
          mkState = cond: mkToggle cond "echo true" "echo false";
        in
        {
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
      * {
        font-family: sans-serif;
        font-weight: bold;
        color: @base05;
      }

      .control-center {
        margin: 8px;
        border-radius: 16px;
        background-color: alpha(@base00, 0.9);
        background-image: linear-gradient(to bottom, alpha(white, 0.05), transparent 50%);
        background-clip: padding-box;
        border: 1px solid alpha(black, 0.2);
        box-shadow: 0 2px 8px alpha(black, 0.4);
      }

      .widget-notifications {
        border-radius: 12px;
      }

      .control-center-list {
        background: transparent;
        border-radius: 12px;
      }

      .notification-group {
        border-radius: 12px;
        padding: 16px 8px 8px;
        background-color: alpha(@base01, 0.5);
        border: 1px solid alpha(black, 0.2);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.3);
      }

      .notification-row .notification-background,
      .control-center .notification-row .notification-background,
      .control-center .notification-row .notification-background:hover,
      .control-center .notification-row .notification-background:active {
        background: transparent;
      }

      .notification-row .notification {
        background-color: @base01;
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.3);
        margin: 4px 0;
      }

      .notification-default-action {
        border-radius: 8px;
      }

      .notification-content {
        background: transparent;
        border: none;
      }

      .notification-action > button {
        background-color: @base02;
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.3);
      }

      .notification-action > button:hover {
        background-color: @base02;
        border: 1px solid alpha(white, 0.1);
      }

      .close-button {
        background-color: @base02;
        color: @base05;
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.3);
      }

      .close-button:hover {
        background-color: alpha(@base08, 0.9);
        border: 1px solid alpha(white, 0.1);
      }

      .widget-title {
        margin: 4px 0;
      }

      .widget-title > button {
        background-color: @base01;
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.3);
      }

      .widget-title > button:hover {
        background-color: @base02;
        border: 1px solid alpha(white, 0.1);
      }

      .widget-dnd > switch {
        background-color: @base01;
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.3);
      }

      .widget-dnd > switch:checked {
        background-color: @base0D;
        border: 1px solid alpha(white, 0.1);
      }

      .widget-dnd > switch slider {
        background-color: @base05;
        border-radius: 6px;
      }

      .widget-buttons-grid > flowbox > flowboxchild > button {
        background-image: radial-gradient(ellipse at 50% 30%, alpha(white, 0.08), transparent 70%);
        background-color: alpha(@base01, 0.3);
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
        box-shadow: inset 0 1px 0 alpha(white, 0.06), 0 1px 2px alpha(black, 0.4);
      }

      .widget-buttons-grid > flowbox > flowboxchild > button:hover {
        background-color: alpha(@base02, 0.5);
        border: 1px solid alpha(white, 0.1);
      }

      .widget-buttons-grid > flowbox > flowboxchild > button.toggle:checked {
        background-image: radial-gradient(ellipse at 50% 30%, alpha(white, 0.14), transparent 70%);
        background-color: alpha(@base0D, 0.9);
        border: 1px solid alpha(white, 0.1);
      }

      .widget-volume scale trough {
        background-color: @base01;
        border-radius: 8px;
        border: 1px solid alpha(black, 0.2);
      }

      .widget-volume scale trough highlight {
        background-color: @base0D;
        border-radius: 8px;
      }

      .widget-volume scale slider {
        background-color: @base05;
      }

      progressbar trough {
        background-color: @base01;
        border: 1px solid alpha(black, 0.2);
      }

      progressbar trough progress {
        background-color: @base0D;
      }
    '';
  };
}
