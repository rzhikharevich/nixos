{
  inputs,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    (inputs.self + /modules/tailscale.nix)
  ];

  users.users.roman.uid = 1001;

  networking = {
    hostName = "lagrange";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      unmanaged = [
        "interface-name:vbr"
        "interface-name:vm-*"
      ];
    };
    wireless.iwd = {
      enable = true;
      settings = {
        Settings.AutoConnect = true;
      };
    };
    useDHCP = false;
  };

  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";
    noPollBatteries = true;
  };

  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--autopower" ];
  };

  programs.fuse.enable = true;

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];

  fonts.fontconfig.hinting = {
    enable = true;
    style = "medium";
  };

  home-manager.users.roman = {
    programs.niri.settings.outputs."HDMI-A-1" = {
      scale = 1;
      variable-refresh-rate = "on-demand";
      mode = {
        width = 3840;
        height = 2160;
        refresh = 119.880;
      };
    };
    stylix = {
      image = pkgs.blackPixel;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/pop.yaml";
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
  };

  system.stateVersion = "26.05";
}
