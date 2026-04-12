{
  security.acme = {
    acceptTerms = true;
    defaults.email = "rzhikharevich@gmail.com";
    certs."fvtt.rzhikharevi.ch" = {
      domain = "fvtt.rzhikharevi.ch";
      dnsProvider = "gandiv5";
      environmentFile = "/etc/secrets/gandi-env";
      webroot = null;
    };
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."fvtt.rzhikharevi.ch" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:30000";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
