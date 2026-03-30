{ config, pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  programs.steam.enable = true;

  documentation.man.cache.enable = false;

  niri-flake.cache.enable = false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  programs.dconf.enable = true;

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

  environment = {
    variables = {
      NIXOS_OZONE_WL = "1";
      SYSTEMD_PAGER = "";
    };
    systemPackages = with pkgs; [
      brightnessctl
      linuxPackages_latest.turbostat
      telegram-desktop
      xwayland-satellite
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.niri = {
      "org.freedesktop.portal.FileChooser" = [ "gtk" ];
    };
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/linux-vt.yaml";
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };
}
