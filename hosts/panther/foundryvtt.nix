{ config, inputs, ... }:
let
  app = config.rzhikharevich.microvmSandboxes.fvtt;

  # Preserve Panther's existing ownership across the virtiofs boundary.
  uid = 993;
  gid = 991;
in
{
  users.users.foundryvtt = {
    inherit uid;
    isSystemUser = true;
    group = "foundryvtt";
  };
  users.groups.foundryvtt = { inherit gid; };

  rzhikharevich.microvmSandboxes.fvtt = {
    service = "foundryvtt";
    allowInternet = true;
    port = 30000;
    dataDir = "/ark/fvtt";
    dataDirRequires = [ "ark-permissions.service" ];

    guestConfig = { pkgs, ... }: {
      imports = [ inputs.foundryvtt.nixosModules.foundryvtt ];
      system.stateVersion = "26.05";
      microvm = {
        vcpu = 2;
        mem = 4096;
        balloon = true;
        vsock = {
          cid = 42;
          ssh.enable = true;
        };
      };

      users.users.root.openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
      users.users.foundryvtt = { inherit uid; };
      users.groups.foundryvtt = { inherit gid; };
      services.openssh = {
        openFirewall = false;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
      systemd.services.foundryvtt.serviceConfig = {
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };
      services.foundryvtt = {
        inherit (app) dataDir port;
        enable = true;
        package = (pkgs.callPackage "${inputs.foundryvtt}/pkgs/foundryvtt" { }).overrideAttrs {
          majorVersion = "14";
          build = "365";
        };
        hostName = "fvtt.rzhikharevi.ch";
        minifyStaticFiles = true;
        proxySSL = true;
        upnp = false;
      };
    };
  };
}
