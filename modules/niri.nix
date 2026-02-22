{ config, lib, pkgs, ... }:
{
  programs.niri.settings = {
    input = {
      keyboard.xkb = "us,ru(macintosh)";

      focus-follows-mouse.enable = true;
      mouse.accel-profile = "flat";

      touchpad = {
        tap = true;
        natural-scroll = true;
        click-method = "clickfinger";
      };

      touch.map-to-output = "eDP-1";
    };
  };
}
