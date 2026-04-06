{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3304038b-c3a9-49b4-aa5e-ae60b5d6b6f5";
    fsType = "xfs";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2D63-1AF7";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/14b1ed22-5e4a-455b-a1aa-95ab63854b18"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  hardware.enableAllFirmware = true;

  services.fprintd.enable = true;

  services.hardware.bolt.enable = true;

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
}
