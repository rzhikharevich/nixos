{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  hardware.asahi.enable = true;
  hardware.asahi.setupAsahiSound = false;
  #hardware.graphics.enable = true;

  hardware.asahi.peripheralFirmwareDirectory = pkgs.requireFile {
    name = "asahi";
    hashMode = "recursive";
    hash = "sha256-Zeebe6rsqt8cZWNZdQ5wckOgR+FBtsLoPMALmwSwPTQ=";
    message = "nix-store --add-fixed sha256 --recursive <path-to-asahi-esp>/asahi";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  boot.kernelPatches = [
    {
      name = "asahi-config";
      patch = null;
      structuredExtraConfig =
        with lib.kernel;
        let
          nope = lib.mkForce no;
          yay = lib.mkForce yes;
        in
        {
          PREEMPT_LAZY = yay;

          RUST = yes;
          ARM64_ACTLR_STATE = yes;
          ARCH_APPLE = yes;
          ARM64_4K_PAGES = no;
          ARM64_16K_PAGES = yes;
          ARM64_64K_PAGES = no;
          ARM64_MEMORY_MODEL_CONTROL = yes;
          ARM_APPLE_CPUIDLE = yes;
          ARM_APPLE_SOC_CPUFREQ = module;
          BT_HCIBCM4377 = module;
          PCIE_APPLE = module;
          NVME_APPLE = module;
          BRCMFMAC = module;
          BRCMFMAC_PCIE = yes;
          TOUCHSCREEN_APPLE_Z2 = module;
          INPUT_MACSMC_INPUT = module;
          I2C_APPLE = module;
          SPI_APPLE = module;
          SPMI_APPLE = module;
          PINCTRL_APPLE_GPIO = module;
          GPIO_MACSMC = module;
          POWER_RESET_MACSMC = module;
          CHARGER_MACSMC = module;
          SENSORS_MACSMC_HWMON = module;
          VIDEO_APPLE_ISP = module;
          DRM = yes;
          DRM_ASAHI = module;
          DRM_ADP = module;
          DRM_APPLE = module;
          DRM_APPLE_AUDIO = yes;
          SND_SOC_APPLE_AOP_AUDIO = module;
          SND_SOC_APPLE_MCA = module;
          SND_SOC_APPLE_MACAUDIO = module;
          SND_SOC_CS42L83 = module;
          SND_SOC_CS42L84 = module;
          SND_SOC_TAS2764 = module;
          SND_SOC_TAS2770 = module;
          HID_APPLE = module;
          HID_MAGICMOUSE = module;
          SERIAL_SAMSUNG = yes;
          SERIAL_SAMSUNG_CONSOLE = yes;
          HID_DOCKCHANNEL = module;
          SPI_HID_APPLE_OF = module;
          SPI_HID_APPLE_CORE = module;
          USB_DWC3_APPLE = module;
          USB_XHCI_PCI_ASMEDIA = yes;
          RTC_DRV_MACSMC = module;
          APPLE_ADMAC = module;
          APPLE_SIO = module;
          MFD_MACSMC = module;
          COMMON_CLK_APPLE_NCO = module;
          APPLE_DART = module;
          APPLE_DOCKCHANNEL = module;
          APPLE_MAILBOX = yes;
          APPLE_PMGR_MISC = yes;
          APPLE_RTKIT = yes;
          APPLE_RTKIT_HELPER = module;
          APPLE_SART = module;
          RUST_APPLE_RTKIT = yes;
          APPLE_AOP = module;
          APPLE_SEP = module;
          APPLE_PMGR_PWRSTATE = yes;
          IIO_AOP_SENSOR_LAS = module;
          IIO_AOP_SENSOR_ALS = module;
          RUST_FW_LOADER_ABSTRACTIONS = yes;
          PWM_APPLE = module;
          APPLE_AIC = yes;
          PHY_APPLE_ATC = module;
          PHY_APPLE_DPTX = module;
          APPLE_M1_CPU_PMU = yes;
          NVMEM_APPLE_EFUSES = module;
          NVMEM_APPLE_SPMI = module;
          MUX_APPLE_DPXBAR = module;
        };
    }
  ];

  # TODO: Check why it defaults to 33 despite 16k pages.
  boot.kernel.sysctl."vm.mmap_rnd_bits" = 31;

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "xfs";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1116-1000";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 24 * 1024; # Some of these LTO build jobs can take quite a lot of RAM...
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
