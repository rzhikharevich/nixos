{
  pkgs,
  config,
  inputs,
  ...
}:

let
  inherit (inputs) microvm;
in
{
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;

  systemd.network.netdevs."20-vbr".netdevConfig = {
    Kind = "bridge";
    Name = "vbr";
  };

  services.resolved.enable = true;

  systemd.network.networks."20-vbr" = {
    matchConfig.Name = "vbr";
    addresses = [ { Address = "100.64.0.1/24"; } ];
    networkConfig = {
      ConfigureWithoutCarrier = true;
    };
  };

  systemd.network.networks."21-vbr-tap" = {
    matchConfig.Name = "vm-*";
    networkConfig.Bridge = "vbr";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "vbr" ];
  };

  microvm.vms.monaco = {
    autostart = false;
    config = {
      imports = [
        microvm.nixosModules.microvm
        ./microvm-base.nix
      ];

      microvm = {
        hypervisor = "cloud-hypervisor";
        #hypervisor = "qemu";
        vcpu = 4;
        mem = 4096;
        socket = "control.socket";
        vsock.cid = 3;
        cloud-hypervisor.extraArgs = [
          "--serial"
          "off"
          "--console"
          "tty"
        ];
        interfaces = [
          {
            type = "tap";
            id = "vm-monaco";
            mac = "02:00:00:00:00:01";
          }
        ];
        shares = [
          {
            proto = "virtiofs";
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
        ];
      };

      services.openssh = {
        enable = true;
        hostKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };
      users.users.root.openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;

      systemd.network.networks."10-lan" = {
        matchConfig.Name = "e*";
        addresses = [ { Address = "100.64.0.2/24"; } ];
        routes = [ { Gateway = "100.64.0.1"; } ];
      };
      networking.nameservers = [
        "8.8.8.8"
        "1.1.1.1"
      ];

      system.stateVersion = "25.11";
    };
  };
}
