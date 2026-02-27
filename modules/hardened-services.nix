{ config, lib, ... }:
let
  hardeningDefaults = lib.mapAttrs (_: lib.mkDefault) {
    # DynamicUser = true;
    ProtectSystem = "full";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateUsers = true;
    NoNewPrivileges = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictNamespaces = true;
    MemoryDenyWriteExecute = true;
    RestrictRealtime = true;
    LockPersonality = true;
    RestrictAddressFamilies = ["AF_UNIX"];
    SystemCallArchitectures = "native";
    SystemCallFilter = "@system-service";  # TODO: Consider stricter default here.
    SystemCallErrorNumber = "EPERM";
  };
in {
  options.rzhikharevich.hardenedServices = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = {};
  };

  options.rzhikharevich.hardeningDefaults = lib.mkOption {
    type = lib.types.attrs;
    default = hardeningDefaults;
    description = "Default systemd service hardening options";
  };

  config.systemd.services = lib.mapAttrs (_: svc: svc // {
    serviceConfig = hardeningDefaults // (svc.serviceConfig or {});
  }) config.rzhikharevich.hardenedServices;
}
