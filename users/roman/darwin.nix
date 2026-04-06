{
  inputs,
  pkgs,
  ...
}:

{
  users.users.roman = {
    home = "/Users/roman";
    shell = pkgs.fish;
  };

  home-manager.users.roman = {
    imports = [
      ./shared.nix
      ./zed.nix
      inputs.revisor.homeManagerModules.default
    ];

    home.file.".hushlogin".text = "";
    home.file.".local/bin/darwin_darkmode".source = "${pkgs.darwin_darkmode}/bin/darwin_darkmode";
    home.sessionPath = [ "/opt/homebrew/bin" ];
    home.sessionVariables.SSH_AUTH_SOCK = "/Users/roman/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";

    programs.ssh.matchBlocks."*".extraOptions.IdentityAgent =
      "/Users/roman/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";

    programs.ssh.matchBlocks.microvm-kickstart = {
      match = ''host "microvm-*.local" exec "set h %n; launchctl kickstart gui/(id -u)/org.nixos.(string replace -r '\.local$' '''''' $h)"'';
    };

    xdg.configFile = {
      "hammerspoon/init.lua".source = ./hammerspoon/init.lua;
      "hammerspoon/oled_mode.lua".source = pkgs.replaceVars ./hammerspoon/oled_mode.lua {
        darwin_darkmode = pkgs.darwin_darkmode;
      };
      "hammerspoon/yabai_padding.lua".source = pkgs.replaceVars ./hammerspoon/yabai_padding.lua {
        yabai = pkgs.yabai;
      };
      "hammerspoon/lgtv_init.lua".source = pkgs.replaceVars ./hammerspoon/lgtv_init.lua {
        lgtv_remote = pkgs.lgtv-remote;
      };
    };

    services.revisor = {
      enable = true;
      units = {
        skhd.script = ''
          exec ${pkgs.darwin_exec}/bin/darwin_exec -t daemon_interactive -d ${pkgs.skhd}/bin/skhd
        '';
        yabai.script = ''
          exec ${pkgs.darwin_exec}/bin/darwin_exec -t daemon_interactive -d ${pkgs.yabai}/bin/yabai
        '';
      };
    };
  };
}
