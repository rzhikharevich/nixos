{ config, lib, pkgs, niri-flake, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/globals.nix
    ./modules/greeter.nix
    ./users/roman/default.nix
  ];

  rzhikharevich.sshPubKeys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIbfIla3NlPdru/+T7qvipOiI3ZcGBhrI6dWhZn6YFnnBuVfbeqoe7k/DAgqTQb9MLlRNIwXJHb/90cU/+7xXV8= sec-one@secretive"
  ];

  boot = {
    kernelParams = [
      "amd_pstate=active" "iommu=pt" "rcutree.enable_rcu_lazy=1" "rcu_nocbs=all"
      "pcie_aspm=force"
    ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.configurationLimit = 5;
      systemd-boot.enable = true;
    };
    initrd = {
      systemd.enable = true;
      luks.devices.cryptroot = {
        device = "/dev/disk/by-uuid/7dc4136d-c383-4971-95f6-bbcbb74fe4a1";
        preLVM = true;
        allowDiscards = true;
      };
    };
  };

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.etc."lvm/lvm.conf".text = lib.mkForce ''
    devices {
      issue_discards = 1
    }
  '';

  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-uuid/3304038b-c3a9-49b4-aa5e-ae60b5d6b6f5";
    fsType = "xfs";
    options = [ "noatime" ];
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/14b1ed22-5e4a-455b-a1aa-95ab63854b18";
    }
  ];

  networking.hostName = "nixform"; # Define your hostname.

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    Settings.AutoConnect = true;
  };

  networking.useDHCP = false;

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    dates = "weekly";
  };

  nixpkgs.overlays = [ niri-flake.overlays.niri ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
  };
  documentation.man.generateCaches = false;
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;
  niri-flake.cache.enable = false;
  environment.variables.NIXOS_OZONE_WL = "1";
  # programs.ccache.enable = true;
  # nix.settings.extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
  nix.settings.download-buffer-size = 1024 * 1048576;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [
    fastfetch
    git
    hdparm
    htop
    pciutils
    powertop
    pstree
    ripgrep
    tmux
    usbutils
    wirelesstools
    (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
      # pyusb
    ]))
  ];

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/linux-vt.yaml";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIbfIla3NlPdru/+T7qvipOiI3ZcGBhrI6dWhZn6YFnnBuVfbeqoe7k/DAgqTQb9MLlRNIwXJHb/90cU/+7xXV8= sec-one@secretive.Roman’s-MacBook-Pro.local"
  ];

  system.stateVersion = "25.11"; # Did you read the comment?
}
