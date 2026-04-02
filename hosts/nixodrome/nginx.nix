{
  services.nginx = {
    enable = true;
    virtualHosts."fvtt.rzhikharevi.ch" = {
      locations."/" = {
        proxyPass = "http://localhost:30000";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
