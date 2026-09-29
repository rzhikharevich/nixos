{
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    (inputs.self + /modules/tailscale.nix)
  ];

  networking = {
    hostId = "b0d86da2";
    hostName = "panther";
    wireless.iwd = {
      enable = true;
      settings = {
        General.EnableNetworkConfiguration = false;
        Settings.AutoConnect = false;
      };
    };
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    wait-online.enable = false;
    networks = {
      "10-wired" = {
        matchConfig.Type = "ether";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV4Config.RouteMetric = 100;
        ipv6AcceptRAConfig.RouteMetric = 100;
      };

      "20-wireless" = {
        matchConfig.Type = "wlan";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV4Config.RouteMetric = 200;
        ipv6AcceptRAConfig.RouteMetric = 200;
      };
    };
  };

  services.openssh.hostKeys = [
    {
      type = "rsa";
      bits = 4096;
      path = "/var/lib/ssh/ssh_host_rsa_key";
    }
    {
      type = "ed25519";
      path = "/var/lib/ssh/ssh_host_ed25519_key";
    }
  ];

  # services.scx = {
  #   enable = true;
  #   scheduler = "scx_lavd";
  #   extraArgs = [ "--autopilot" ];
  # };

  system.stateVersion = "26.05";
}
