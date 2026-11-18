{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  datasets = lib.sort builtins.lessThan (lib.map (dataset: "ark/${dataset}") [ "fvtt" ]);
  snapshotName = "rustic-backup";
  snapshotRoot = "/run/rustic-snapshots";
  snapshots = map (dataset: "${dataset}@${snapshotName}") datasets;

  cleanupSnapshots = lib.concatMapStringsSep "\n" (dataset: ''
    if mountpoint -q ${lib.escapeShellArg "${snapshotRoot}/${dataset}"}; then
      umount ${lib.escapeShellArg "${snapshotRoot}/${dataset}"}
    fi
    if zfs list -H -t snapshot ${lib.escapeShellArg "${dataset}@${snapshotName}"} >/dev/null 2>&1; then
      zfs destroy ${lib.escapeShellArg "${dataset}@${snapshotName}"}
    fi
  '') (lib.reverseList datasets);  # Reverse of sorted list => unmount children first.

  rusticConfig = (pkgs.formats.toml { }).generate "rustic-ark.toml" {
    repository = {
      repository = "opendal:sftp";
      password-file = "$CREDENTIALS_DIRECTORY/rustic-password";

      options = {
        endpoint = "ssh://u720039.your-storagebox.de:23";
        user = "u720039";
        key = "$CREDENTIALS_DIRECTORY/rustic-ssh";
        root = "/home/rustic/ark";
      };
    };

    backup.snapshots = [
      {
        sources = [ "${snapshotRoot}/ark" ];
        as-path = "/ark";
      }
    ];

    forget = {
      keep-daily = 14;
      keep-weekly = 8;
      keep-monthly = 12;
    };
  };

  rusticEnvironment = {
    RUSTIC_PROFILE_SUBSTITUTE_ENV = "true";
    # The openssh crate creates its control sockets under XDG_STATE_HOME.
    XDG_STATE_HOME = "/tmp/rustic";
  };

  rusticSandbox = {
    # DynamicUser + CacheDirectory + PrivatePIDs = boom.
    # See https://github.com/systemd/systemd/issues/41014.
    User = "rustic";
    Group = "rustic";
    CapabilityBoundingSet = "";
    CacheDirectoryMode = "0700";
    LoadCredential = [
      "rustic-password:${config.sops.secrets.rustic-password.path}"
      "rustic-ssh:${config.sops.secrets.rustic-ssh.path}"
    ];
    BindReadOnlyPaths = [
      "${rusticConfig}:/etc/rustic/ark.toml"
      "/etc/resolv.conf"
      "/etc/hosts"
      "/etc/localtime"
      "/etc/nsswitch.conf"
      # nscd resolves the service user for OpenSSH and names for file owners.
      # The empty root has no /var/run -> /run symlink for glibc's socket path.
      "/run/nscd/socket:/var/run/nscd/socket"
      "/etc/ssh/ssh_known_hosts"
    ];
    MountAPIVFS = true;
    PrivateDevices = true;
    PrivateMounts = true;
    PrivateTmp = true;
    PrivateUsers = true;
    PrivatePIDs = true;
    PrivateIPC = true;
    RemoveIPC = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    ProtectSystem = "strict";
    ProtectHome = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    NoNewPrivileges = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      # DAC_READ_SEARCH + open_by_handle_at allow sandbox escapes. See "Docker Shocker".
      "~@mount @aio name_to_handle_at open_by_handle_at"
    ];
    SystemCallErrorNumber = "EPERM";
    UMask = "0077";
  };
in

{
  users.groups.rustic = { };
  users.users.rustic = {
    isSystemUser = true;
    group = "rustic";
  };

  environment.systemPackages = [ pkgs.rustic ];

  sops.secrets = {
    rustic-password = { };
    rustic-ssh = {
      sopsFile = inputs.nixos-private + /secrets/panther-rustic-ssh.json;
      format = "binary";
    };
  };

  programs.ssh.knownHosts.rustic-storagebox = {
    hostNames = [ "[u720039.your-storagebox.de]:23" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  };

  environment.etc."rustic/ark.toml".source = rusticConfig;

  systemd.services.rustic-snapshots = {
    description = "Prepare ZFS snapshots for Rustic";
    requires = [ "disko-zfs-ark.service" ];
    after = [ "disko-zfs-ark.service" ];
    unitConfig = {
      StopWhenUnneeded = true;
    };
    path = [
      config.boot.zfs.package
      pkgs.coreutils
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "rustic-snapshots";
      RuntimeDirectoryMode = "0700";
      PrivateMounts = false;
      NoNewPrivileges = true;
      UMask = "0077";
    };
    script = ''
      ${cleanupSnapshots}
      zfs snapshot ${lib.escapeShellArgs snapshots}
      ${lib.concatMapStringsSep "\n" (dataset: ''
        mkdir -p ${lib.escapeShellArg "${snapshotRoot}/${dataset}"}
        mount.zfs -o ro,nodev,nosuid,noexec \
          ${lib.escapeShellArg "${dataset}@${snapshotName}"} \
          ${lib.escapeShellArg "${snapshotRoot}/${dataset}"}
      '') datasets}
    '';
    # ExecStopPost also runs when preparation fails partway through.
    postStop = cleanupSnapshots;
  };

  systemd.services.rustic-backup = {
    description = "Back up ark ZFS snapshots with Rustic";
    restartIfChanged = false;
    startAt = "daily";
    wants = [ "network-online.target" "nscd.service" ];
    bindsTo = [ "rustic-snapshots.service" ];
    after = [
      "network-online.target"
      "nscd.service"
      "rustic-snapshots.service"
    ];
    path = [ pkgs.openssh ];
    environment = rusticEnvironment // {
      RUSTIC_CACHE_DIR = "/var/cache/rustic";
    };
    confinement = {
      enable = true;
      packages = [
        pkgs.openssh
        pkgs.tzdata
      ];
    };
    script = ''
      ${lib.getExe pkgs.rustic} -P /etc/rustic/ark backup
      ${lib.getExe pkgs.rustic} -P /etc/rustic/ark forget --prune
    '';
    serviceConfig = rusticSandbox // {
      Type = "oneshot";
      AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
      CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
      CacheDirectory = "rustic";
      BindReadOnlyPaths = rusticSandbox.BindReadOnlyPaths ++ [ "${snapshotRoot}/ark" ];

      # The capability must apply to host-owned files.
      PrivateUsers = false;
    };
  };

  systemd.timers.rustic-backup.timerConfig.Persistent = true;
}
