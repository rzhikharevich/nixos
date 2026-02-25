{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/globals.nix
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
      # TODO: Reconsideer iommu=pt.
      "amd_pstate=active" "iommu=pt"

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

  documentation.man.generateCaches = false;

  niri-flake.cache.enable = false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # programs.ccache.enable = true;

  environment = {
    variables.NIXOS_OZONE_WL = "1";
    systemPackages = with pkgs; [
      brightnessctl
      claude-code
      fastfetch
      git
      hdparm
      htop
      nvd
      pciutils
      powertop
      pstree
      ripgrep
      strace
      tmux
      usbutils
      wirelesstools
      (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
        # pyusb
      ]))
    ];
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/linux-vt.yaml";
  };

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
