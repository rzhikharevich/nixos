{ pkgs, ... }:

{
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;

    initrd.systemd = {
      enable = true;
      services.rollback-root = {
        description = "Roll back the ephemeral ZFS root";
        wantedBy = [ "initrd.target" ];
        requires = [ "zfs-import-rpool.service" ];
        after = [ "zfs-import-rpool.service" ];
        before = [ "sysroot.mount" ];
        path = [ pkgs.zfs ];
        unitConfig.DefaultDependencies = false;
        serviceConfig.Type = "oneshot";
        script = "zfs rollback -r rpool/nixos/empty@start";
      };
    };

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
}
