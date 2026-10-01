{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    (inputs.self + /modules/lvm.nix)
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };

    initrd.luks.devices.cryptroot = {
      device = "/dev/disk/by-partuuid/eec9610e-2c50-42e7-a381-b1226305816a";
      preLVM = true;
      allowDiscards = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };
}
