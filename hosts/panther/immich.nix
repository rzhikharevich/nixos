{ config, ... }:

{
  services.immich = {
    enable = true;
    port = 30001;
    mediaLocation = "/ark/immich";
  };

  systemd.services.immich-server = {
    requires = [ "ark-permissions.service" ];
    after = [ "ark-permissions.service" ];
    unitConfig = {
      RequiresMountsFor = config.services.immich.mediaLocation;
      AssertPathIsMountPoint = config.services.immich.mediaLocation;
    };
  };

  services.redis.servers.immich.logLevel = "warning";
  services.postgresql.dataDir = "/ark/postgres";

  systemd.services.postgresql = {
    requires = [ "ark-permissions.service" ];
    after = [ "ark-permissions.service" ];
    unitConfig = {
      RequiresMountsFor = config.services.postgresql.dataDir;
      AssertPathIsMountPoint = config.services.postgresql.dataDir;
    };
  };
}
