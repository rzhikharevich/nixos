{
  config,
  inputs,
  pkgs,
  ...
}:

let
  # `systemd-machine-id-setup --root` looks for etc/machine-id beneath it.
  machineIdRoot = "/var/lib";
  machineIdFile = "${machineIdRoot}/etc/machine-id";
  zfs = "${config.boot.zfs.package}/sbin/zfs";
in

{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./foundryvtt.nix
    ./nginx.nix
  ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      extraPools = [ "ark" ];
      requestEncryptionCredentials = [ "rpool" ];
    };
  };

  # Make SOPS's age key available before stage-2 pool imports.
  fileSystems."/var/lib".neededForBoot = true;

  sops.useSystemdActivation = true;
  sops.secrets = {
    roman-password = {
      neededForUsers = true;
    };
  };

  # SOPS's regular service runs after local-fs.target, which depends on this
  # import through disko-zfs. Decrypt ark's key here to avoid an ordering cycle.
  systemd.services.zfs-import-ark = {
    environment.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
    postStart = ''
      set -o pipefail
      if [ "$(${zfs} get -H -o value keystatus ark)" != available ]; then
        ${pkgs.sops}/bin/sops --decrypt --input-type binary --output-type binary \
          ${inputs.nixos-private + /secrets/zfs-ark.json} \
          | ${zfs} load-key -L file:///dev/stdin ark
      fi
    '';
  };

  networking = {
    hostId = "b0d86da2";
    hostName = "panther";
  };

  services.openssh.hostKeys = [
    {
      type = "ed25519";
      path = "/var/lib/ssh/ssh_host_ed25519_key";
    }
  ];

  # Symlink + commit-override against the persistent copy, paired with the
  # `uninitialized\n` seed below. Per
  # https://github.com/NixOS/nixpkgs/pull/351151#issuecomment-2440122776
  environment.etc."machine-id".source = machineIdFile;

  # Empty first list element is systemd's drop-in syntax for clearing a
  # list-typed option before redefining it.
  systemd.services.systemd-machine-id-commit = {
    unitConfig.ConditionPathIsMountPoint = [
      ""
      machineIdFile
    ];
    serviceConfig.ExecStart = [
      ""
      "systemd-machine-id-setup --commit --root ${machineIdRoot}"
    ];
  };

  # systemd-machine-id-setup needs the `uninitialized\n` marker (not an
  # empty file) to mount its tmpfs and emit a fresh id.
  disko.devices.zpool.rpool.datasets."nixos/var/lib".postMountHook = ''
    machine_id=${config.disko.rootMountPoint}${machineIdFile}
    if [ ! -e "$machine_id" ]; then
      mkdir -p "$(dirname "$machine_id")"
      printf 'uninitialized\n' > "$machine_id"
    fi
  '';

  users = {
    mutableUsers = false;
    users.roman.hashedPasswordFile = config.sops.secrets.roman-password.path;
  };

  users.users.roman.extraGroups = [ "foundryvtt" ];

  system.stateVersion = "26.05";
}
