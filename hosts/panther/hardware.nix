{
  lib,
  ...
}:

{
  boot.initrd.availableKernelModules = [
    "ahci"
    "igc" # Intel I226-LM
    "nvme"
    "r8169" # RTL8127
    "usbhid"
    "xhci_pci"
  ];

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  services = {
    fwupd.enable = true;
    hardware.bolt.enable = true;
    zfs.autoScrub.enable = true;
  };

  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-KINGSTON_SKC3000S1024G_50026B7384370030";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            size = "8G";
            content = {
              type = "swap";
              randomEncryption = true;
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      options = {
        ashift = "12";
      };
      rootFsOptions = {
        acltype = "posixacl";
        atime = "off";
        compression = "zstd";
        mountpoint = "none";
        xattr = "sa";
        encryption = "on";
        keyformat = "passphrase";
      };
      datasets = {
        nixos = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "nixos/empty" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/";
        };
        "nixos/home" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/home";
        };
        "nixos/nix" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/nix";
        };
        "nixos/var" = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "nixos/var/log" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/var/log";
        };
        "nixos/var/lib" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/var/lib";
        };
      };
    };
  };

  disko.zfs = {
    enable = true;
    settings = {
      datasets."ark/fvtt".properties.mountpoint = "/ark/fvtt";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
