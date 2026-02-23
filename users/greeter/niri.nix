{ pkgs, ... }:
let
  safeSuspend = import ../../scripts/safe-suspend.nix { inherit pkgs; };
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

  wlgreetConfig = pkgs.writeText "greetd-wlgreet-config" ''
    command = "${pkgs.niri}/bin/niri-session"
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
in
{
  programs.niri.settings = {
    outputs."eDP-1" = {
      background-color = "000000";
      scale = 2.0;
    };

    hotkey-overlay.skip-at-startup = true;

    spawn-at-startup = [
      { argv = [
        "${pkgs.swayidle}/bin/swayidle" "-w"
        "before-sleep" "${pkgs.niri}/bin/niri msg action power-off-monitors"
        "after-resume" "${pkgs.niri}/bin/niri msg action power-on-monitors"
        "timeout" "30" "${safeSuspend}"
      ]; }
      { argv = [ "${pkgs.wvkbd}/bin/wvkbd-mobintl" "--hidden" "-L" "400" "--fn" "sans 20" ]; }
      { argv = [ "sh" "-c" "${pkgs.wlgreet}/bin/wlgreet --config ${wlgreetConfig}; ${pkgs.niri}/bin/niri msg action quit --skip-confirmation" ]; }
    ];

    binds = {
      "XF86AudioRaiseVolume".action.spawn = [ "pkill" "-SIGRTMIN" "wvkbd-mobintl" ];
      "XF86AudioLowerVolume".action.spawn = [ "${powerMenu}" ];
    };
  };
}
