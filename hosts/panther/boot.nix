{
  config,
  pkgs,
  ...
}:

{
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;

    initrd = {
      systemd = {
        enable = true;
        users.root.shell = "/bin/systemd-tty-ask-password-agent";
        network = {
          enable = true;
          wait-online.enable = false;
          networks."10-wired" = config.systemd.network.networks."10-wired";
        };
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

      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = config.rzhikharevich.sshPubKeys;
          hostKeys = [ "/var/lib/secrets/initrd/ssh_host_ed25519_key" ];
        };
      };
    };

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
}
