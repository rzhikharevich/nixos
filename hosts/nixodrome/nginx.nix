{ config, ... }:

{
  sops.secrets.porkbun-env = { };

  security.acme = {
    acceptTerms = true;
    defaults.email = "rzhikharevich@gmail.com";
    certs."im.unholy.systems" = {
      domain = "im.unholy.systems";
      dnsProvider = "porkbun";
      environmentFile = config.sops.secrets.porkbun-env.path;
      webroot = null;
    };
  };

  services.nginx = {
    enable = true;
    clientMaxBodySize = "16g";
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."im.unholy.systems" = {
      listenAddresses = [ "100.102.126.120" ];
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:30001";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    80
    443
  ];
}
