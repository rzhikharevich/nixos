{
  pkgs,
  lib,
  ...
}:
{
  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
    settings = {
      fps_limit = 116;
      no_display = true;
    };
  };

  stylix = {
    image = pkgs.blackPixel;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/pop.yaml";
  };

  programs.niri.settings = {
    outputs."HDMI-A-1" = {
      scale = 1;
      variable-refresh-rate = "on-demand";
      mode = {
        width = 3840;
        height = 2160;
        refresh = 119.880;
      };
    };

    window-rules = [
      {
        matches = [ { app-id = "^steam_app_[0-9]+$"; } ];
        variable-refresh-rate = true;
      }
    ];
  };

  programs.firefox.profiles.default.settings = {
    "media.hardware-video-decoding.enabled" = true;
    "media.hardware-video-decoding-vulkan.enabled" = true;
    "media.hardware-video-decoding-vulkan.direct-export.enabled" = true;
  };

  programs.zed-editor = {
    userSettings.theme = lib.mkForce {
      light = "Dark OLED";
      dark = "Dark OLED";
    };

    extensions = [
      "dark-oled"
    ];
  };
}
