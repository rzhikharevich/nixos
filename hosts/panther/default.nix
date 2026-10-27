{
  config,
  ...
}:

let
  # `systemd-machine-id-setup --root` looks for etc/machine-id beneath it.
  machineIdRoot = "/var/lib";
  machineIdFile = "${machineIdRoot}/etc/machine-id";
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
      requestEncryptionCredentials = true;
    };
  };

  sops.secrets = {
    roman-password = {
      neededForUsers = true;
    };
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
