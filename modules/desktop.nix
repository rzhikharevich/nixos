{ config, lib, pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
  };

  programs.steam.enable = true;

  documentation.man.cache.enable = false;

  niri-flake.cache.enable = false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  programs.dconf.enable = true;
  # programs.ccache.enable = true;

  environment = {
    variables = {
      NIXOS_OZONE_WL = "1";
      SYSTEMD_PAGER = "";  # Super annoying most of the time.
    };
    systemPackages = with pkgs; [
      brightnessctl
      clang
      claude-code
      fastfetch
      file
      gcc
      git
      gnumake
      hdparm
      htop
      hwloc
      iw
      jq
      ncdu
      nvd
      pciutils
      powerstat
      powertop
      pstree
      ripgrep
      strace
      telegram-desktop
      tmux
      pkgs.linuxPackages_latest.turbostat
      usbutils
      wirelesstools
      xwayland-satellite
      xxd

      (pkgs.fenix.complete.withComponents [
         "cargo"
         "clippy"
         "rust-analyzer"
         "rust-src"
         "rustc"
         "rustfmt"
      ])

      (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
        ptpython
      ]))
    ];
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

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
