{ config, pkgs, lib, ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      auth = {
        fingerprint = {
          enabled = true;
          ready_message = "🫆";
          present_message = "🧑‍💻";
        };
      };

      background = {
        monitor = "";
        path = config.stylix.image;
        blur_passes = 3;
      };

      input-field = {
        monitor = "";
        fail_text = "";
        fade_on_empty = false;
        placeholder_text = "";
        font_family = "JetBrains Mono";
        position = "0, 256";
        halign = "center";
        valign = "bottom";
        rounding = 14;
        shadow_passes = 1;
      };

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 256;
          font_family = "JetBrains Mono";
          position = "0, -80";
          halign = "center";
          valign = "top";
          shadow_passes = 1;
        }
        {
          monitor = "";
          text = "cmd[] " + (lib.strings.join "; " [
            "if [ -n \"$FPRINTFAIL\" ]"
            "then echo 💥"
            "else echo $FPRINTPROMPT"
            "fi"
          ]);
          font_size = 32;
          position = "248, 280";
          halign = "center";
          valign = "bottom";
          shadow_passes = 1;
        }
      ];
    };
  };
}
