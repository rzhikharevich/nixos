{ config, lib, pkgs, ... }:
{
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "us,ru(macintosh)";

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

    spawn-at-startup = [
      { argv = [ "${pkgs.swaybg}/bin/swaybg" "-m" "fill" "-i" config.stylix.image ]; }
    ];

    outputs = {
      "eDP-1" = {
        scale = 1.5;
        variable-refresh-rate = true;
        backdrop-color = "000000";
      };
    };

    cursor = {
      size = 96;
      hide-when-typing = true;
    };
  };
}
