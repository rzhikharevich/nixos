{
  config,
  ...
}:

let
  emptyRootSnapshot = "${config.fileSystems."/".device}@start";
  initrdHostKey = "/var/lib/secrets/initrd/ssh_host_ed25519_key";
in

{
  disko.devices.zpool.rpool.datasets = {
    "nixos/empty".postCreateHook = ''
      zfs list -H -o name -t snapshot ${emptyRootSnapshot} >/dev/null 2>&1 \
        || zfs snapshot ${emptyRootSnapshot}
    '';

    # The bootloader installer copies this key into the initrd, so it has to
    # exist before the first install.
    "nixos/var/lib".postMountHook = ''
      initrd_host_key=${config.disko.rootMountPoint}${initrdHostKey}
      if [ ! -e "$initrd_host_key" ]; then
        mkdir -p "$(dirname "$initrd_host_key")"
        ${config.programs.ssh.package}/bin/ssh-keygen -t ed25519 -N "" \
          -C ${config.networking.hostName}-initrd -f "$initrd_host_key"
      fi
    '';
  };

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
          path = [ config.boot.zfs.package ];
          unitConfig.DefaultDependencies = false;
          serviceConfig.Type = "oneshot";
          script = "zfs rollback -r ${emptyRootSnapshot}";
        };
      };

      network = {
        enable = true;
        ssh = {
          enable = true;
          hostKeys = [ initrdHostKey ];
        };
      };
    };

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
    };
  };
}
