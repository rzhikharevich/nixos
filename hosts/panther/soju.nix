{ config, lib, ... }:
let
  certPath = "/var/lib/acme/irc.unholy.systems";
  domain = "irc.unholy.systems";
in
{
  security.acme.certs.${domain} = {
    domain = domain;
    dnsProvider = "porkbun";
    environmentFile = config.sops.secrets.porkbun-env.path;
    webroot = null;
    reloadServices = [ "soju.service" ];
    group = "soju";
  };

  users = {
    users.soju = {
      isSystemUser = true;
      group = "soju";
    };
    groups.soju = { };
  };

  services.soju = {
    enable = true;
    hostName = domain;
    tlsCertificate = "${certPath}/fullchain.pem";
    tlsCertificateKey = "${certPath}/key.pem";
  };

  systemd.services.soju.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "soju";
    Group = "soju";
    ReadOnlyPaths = certPath;
  };
}
