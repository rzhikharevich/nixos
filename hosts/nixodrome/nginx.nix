{ config, ... }:

{
  sops.secrets = {
    porkbun-env = { };
    foundryvtt-basicauth = {
      owner = "nginx";
      reloadUnits = [ "nginx.service" ];
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "rzhikharevich@gmail.com";
    certs = {
      "fvtt.rzhikharevi.ch" = {
        domain = "fvtt.rzhikharevi.ch";
        dnsProvider = "gandiv5";
        environmentFile = "/etc/secrets/gandi-env";
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
      "im.unholy.systems" = {
        listenAddresses = [ "100.102.126.120" ];
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:30001";
          proxyWebsockets = true;
        };
      };
      "fvtt.rzhikharevi.ch" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:30000";
          proxyWebsockets = true;
        };
        basicAuthFile = config.sops.secrets.foundryvtt-basicauth.path;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
