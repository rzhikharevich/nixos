{ config, ... }:

{
  sops.secrets = {
    gandi-token = { };
    porkbun-env = { };
    foundryvtt-basicauth = {
      owner = "nginx";
      reloadUnits = [ "nginx.service" ];
    };
  };

  sops.templates."gandi.env" = {
    owner = "acme";
    content = ''
      GANDIV5_PERSONAL_ACCESS_TOKEN=${config.sops.placeholder.gandi-token}
    '';
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "rzhikharevich@gmail.com";
    certs = {
      "fvtt.rzhikharevi.ch" = {
        domain = "fvtt.rzhikharevi.ch";
        dnsProvider = "gandiv5";
        environmentFile = config.sops.templates."gandi.env".path;
        webroot = null;
      };
      "im.unholy.systems" = {
        domain = "im.unholy.systems";
        dnsProvider = "porkbun";
        environmentFile = config.sops.secrets.porkbun-env.path;
        webroot = null;
      };
    };
  };

  services.nginx = {
    enable = true;
    clientMaxBodySize = "16g";
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "fvtt.rzhikharevi.ch" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:30000";
          proxyWebsockets = true;
        };
        basicAuthFile = config.sops.secrets.foundryvtt-basicauth.path;
      };
      "im.unholy.systems" = {
        listenAddresses = [ "100.83.29.93" ];
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.immich.port}";
          proxyWebsockets = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
