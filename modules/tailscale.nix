{
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--accept-dns=false"
    ];
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];
}
