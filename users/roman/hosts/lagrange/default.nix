{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
    settings.fps_limit = 116;
  };

  programs.niri.settings.window-rules = [
    {
      matches = [ { app-id = "^steam_app_[0-9]+$"; } ];
      variable-refresh-rate = true;
    }
  ];

  programs.firefox.profiles.default.settings = {
    "meida.hardware-video-decoding.enabled" = true;
    "media.hardware-video-decoding-vulkan.enabled" = true;
    "media.hardware-video-decoding-vulkan.direct-export.enabled" = true;
  };
}
