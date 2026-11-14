{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  zfs = "${config.boot.zfs.package}/sbin/zfs";
  arkKeyLocation = "file://${config.sops.secrets.zfs-ark.path}";
  arkDatasets = lib.filterAttrs (
    name: _: name == "ark" || lib.hasPrefix "ark/" name
  ) config.disko.zfs.settings.datasets;
  arkMountDatasets = lib.filterAttrs (
    _: value: (value.properties.canmount or "on") != "off"
  ) arkDatasets;
  arkMountPoints = lib.mapAttrsToList (dataset: _: "/" + dataset) arkMountDatasets;
  arkZfsSpec = (pkgs.formats.json { }).generate "disko-zfs-ark-spec.json" (
    config.disko.zfs.settings
    // {
      datasets = arkDatasets;
      ignoredDatasets = [
        "rpool"
        "rpool/*"
      ];
    }
  );
  arkDiskoZfs = action: ''
    ${lib.getExe config.disko.zfs.package} \
      --log-level ${config.disko.zfs.settings.logLevel} ${action} --spec ${arkZfsSpec}
  '';
in

{
  disko.zfs.settings = {
    # Keep ark out of the main disko-zfs instance.
    ignoredDatasets = [
      "ark"
      "ark/*"
    ];
    datasets = {
      ark.properties = {
        mountpoint = "/ark";
        canmount = "off";
        xattr = "sa";
        dnodesize = "auto";
        keylocation = arkKeyLocation;
        atime = "off";
      };
      "ark/fvtt".properties = {
        canmount = "noauto";
      };
      "ark/immich".properties = {
        canmount = "noauto";
        recordsize = "1M";
      };
      "ark/postgres".properties = {
        canmount = "noauto";
        recordsize = "32K";
      };
      "ark/syncthing".properties = {
        canmount = "noauto";
      };
    };
  };

  sops.secrets.zfs-ark = {
    sopsFile = inputs.nixos-private + /secrets/zfs-ark.json;
    format = "binary";
  };

  fileSystems = lib.mapAttrs' (
    dataset: value:
    lib.nameValuePair ("/" + dataset) {
      device = dataset;
      fsType = "zfs";
      options = [
        "zfsutil"
        "nofail"
        "x-systemd.requires=disko-zfs-ark.service"
      ];
    }
  ) arkMountDatasets;

  systemd.services.ark-permissions = {
    description = "Set ownership and permissions for ark datasets";
    unitConfig = {
      RequiresMountsFor = arkMountPoints;
      AssertPathIsMountPoint = arkMountPoints;
    };
    serviceConfig.Type = "oneshot";
    path = [ pkgs.coreutils ];
    script = ''
      chown foundryvtt:foundryvtt /ark/fvtt
      chmod 0750 /ark/fvtt
      chown immich:immich /ark/immich
      chmod 0700 /ark/immich
      chown postgres:postgres /ark/postgres
      chmod 0700 /ark/postgres
      chown syncthing:syncthing /ark/syncthing
      chmod 0700 /ark/syncthing
    '';
  };

  systemd.services.zfs-import-ark = {
    requires = [ "sops-install-secrets.service" ];
    after = [
      "zfs-mount.service"
      "sops-install-secrets.service"
    ];
    requiredBy = lib.mkForce [ ];
    before = lib.mkForce [
      "shutdown.target"
    ];
    postStart = ''
      if [ "$(${zfs} get -H -o value keystatus ark)" != available ]; then
        ${zfs} load-key -L ${lib.escapeShellArg arkKeyLocation} ark
      fi
    '';
  };

  systemd.services.disko-zfs-ark = {
    description = "Configure ark ZFS datasets";
    unitConfig.DefaultDependencies = false;
    requires = [ "zfs-import-ark.service" ];
    after = [ "zfs-import-ark.service" ];
    before = [
      "shutdown.target"
    ];
    conflicts = [ "shutdown.target" ];
    path = [ config.boot.zfs.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = arkDiskoZfs "apply";
  };

  system.activationScripts.disko-zfs-ark = {
    supportsDryActivation = true;
    text = ''
      if [[ "$NIXOS_ACTION" == "dry-activate" ]]; then
        echo "Dry-activating disko-zfs-ark..."
        export PATH="${config.boot.zfs.package}/sbin:$PATH"
        ${arkDiskoZfs "plan"}
      fi
    '';
  };
}
