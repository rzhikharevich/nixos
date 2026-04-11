{ sshPubKeys }:
{ pkgs, ... }:

{
  boot.initrd.systemd.enable = false;
  boot.kernelParams = [
    "8250.nr_uarts=0"
    "audit=0"
  ];
  boot.initrd.includeDefaultModules = false;
  boot.initrd.kernelModules = [
    # vsock
    "vsock"
    "vmw_vsock_virtio_transport_common"
    "vmw_vsock_virtio_transport"
    # virtio (disk, net, fs, console, rng)
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
    "virtiofs"
    "virtio_console"
    "virtio_rng"
  ];

  networking.useDHCP = false;
  networking.firewall.enable = false;
  networking.tempAddresses = "disabled";
  networking.nameservers = [
    "8.8.8.8"
    "1.1.1.1"
  ];

  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
  systemd.settings.Manager.DefaultTimeoutStopSec = "5s";

  systemd.mounts = [
    {
      what = "store";
      where = "/nix/store";
      overrideStrategy = "asDropin";
      unitConfig.DefaultDependencies = false;
    }
  ];

  fileSystems."/nix/store".fsType = "virtiofs";

  systemd.sockets.systemd-journald-audit.enable = false;
  systemd.services.systemd-journald-audit.enable = false;
  systemd.sockets.sshd-vsock.enable = false;
  systemd.services.systemd-vconsole-setup.enable = false;
  systemd.services.systemd-journal-catalog-update.enable = false;
  systemd.services.systemd-update-utmp.enable = false;

  security.sudo.enable = false;
  security.wrappers = pkgs.lib.mkForce {
    unix_chkpwd = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${pkgs.pam}/bin/unix_chkpwd";
    };
  };

  microvm.shares = [
    {
      proto = "virtiofs";
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }
  ];

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = sshPubKeys;

  system.stateVersion = "25.11";
}
