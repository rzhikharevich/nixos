{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/globals.nix
    ./modules/hardened-services.nix
    ./modules/pam-no-fprint.nix
    ./modules/ssh-inhibit-suspend.nix
    ./users/greeter/default.nix
    ./users/roman/default.nix
  ];

  rzhikharevich.sshPubKeys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIbfIla3NlPdru/+T7qvipOiI3ZcGBhrI6dWhZn6YFnnBuVfbeqoe7k/DAgqTQb9MLlRNIwXJHb/90cU/+7xXV8= sec-one@secretive"
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      download-buffer-size = 1024 * 1048576;
      # extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
      trusted-users = [ "@wheel" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    optimise = {
      automatic = true;
      dates = "weekly";
    };
  };

  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;

  boot = {
    kernelParams = [
      # TODO: Reconsider iommu=pt.
      "iommu=pt"

      # TODO: Test amd_pstate=passive with manually set minimum frequencies (which default to the
      # min non-linear frequency = ~1100 MHz, not the absolute minimum = ~400 MHz which is what
      # active does in power-saving mode).
      "amd_pstate=active"

      # Experiment: Assign IRQs to boot CPU cores + cores with the highest amd_pstate_prefcore_ranking
      # which pairs well with scx_lavd since it tries to pack threads on the latter (the boot core
      # can't be prevented from receiving IRQs).
      "irqaffinity=0,1,8,9"

      # threadirqs is interesting since it would presumably bring IRQs under lavd's control but
      # it's probably more trouble (overhead) than it's worth.

      # Lockup watchdogs are not that relevant on laptops unless I'll have to debug kernel bugs
      # (hopefully not).
      "nowatchdog"

      # Enabling this makes the per-cpu workqueues which
      # were observed to contribute significantly to power
      # consumption unbound, leading to measurably lower
      # power usage at the cost of small performance
      # overhead.
      #   - https://docs.kernel.org/admin-guide/kernel-parameters.html
      "workqueue.power_efficient=1"

      # rcutree.enable_rcu_lazy allows the kernel to delay RCU callbacks to decrease the amount of
      # RCU grace periods and therefore let idle CPUs sleep for longer. rcu_nocbs= is required for
      # it to work on a given CPU, enable it for all.
      #   - https://lwn.net/Articles/988638
      "rcutree.enable_rcu_lazy=1" "rcu_nocbs=all"

      # PCIe ASPM might be negotiated to be off by the BIOS for spurious reasons, force enable it.
      #   - https://wireless.docs.kernel.org/en/latest/en/users/documentation/aspm.html
      #
      # Note that pcie_aspm.policy is already set to powersupersave by nixos-hardware.
      "pcie_aspm=force"
    ];
    extraModprobeConfig = ''
      options iwlwifi power_save=1 uapsd_disable=3
      options iwlmvm power_scheme=3
    '';
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
    };
    initrd = {
      systemd.enable = true;
      luks.devices.cryptroot = {
        device = "/dev/disk/by-uuid/7dc4136d-c383-4971-95f6-bbcbb74fe4a1";
        preLVM = true;
        allowDiscards = true;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl."vm.dirty_writeback_centisecs" = 1500;
  };

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
    { device = "/dev/disk/by-uuid/14b1ed22-5e4a-455b-a1aa-95ab63854b18"; }
  ];

  networking = {
    hostName = "nixform";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    wireless.iwd = {
      enable = true;
      settings = {
        Settings.AutoConnect = true;
      };
    };
    useDHCP = false;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

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

  services.fprintd.enable = true;
  security.pam.services.hyprlock = {};

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

  documentation.man.cache.enable = false;

  niri-flake.cache.enable = false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

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
      iw
      ncdu
      nvd
      pciutils
      powerstat
      powertop
      pstree
      ripgrep
      strace
      tmux
      linuxPackages_latest.turbostat
      usbutils
      wirelesstools
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
        # pyusb
      ]))
    ];
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

  fonts.fontconfig.confPackages = [
    (pkgs.writeTextDir "etc/fonts/conf.d/61-noto-emoji-monochrome.conf" ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="scan">
          <test name="family"><string>Noto Emoji</string></test>
          <edit name="family" mode="append"><string>Monochrome Emoji</string></edit>
        </match>
      </fontconfig>
    '')
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

  services.iio-niri.enable = true;

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

  # Reportedly, suspending fingerprint readers (i.e. 27c6:6092 in this case) might cause issues.
  # Additionally, don't suspend input devices for obvious reasons.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="27c6", ATTR{idProduct}=="6092", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", RUN+="/bin/sh -c 'echo on > /sys%p/../power/control'"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/control}="auto"
  '';

  systemd.tmpfiles.rules = [
    "w /sys/devices/pci0000:00/0000:00:08.1/0000:c4:00.0/drm/card1/card1-eDP-1/amdgpu/panel_power_savings - - - - 2"
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;

  system.stateVersion = "25.11"; # Did you read the comment?
}
