{
  config,
  ...
}:

{
  boot = {
    kernelParams = [
      "log_buf_len=1M"
      "rcutree.enable_rcu_lazy=1"
      "rcu_nocbs=all"
      "zswap.enabled=1"
    ];

    loader = {
      systemd-boot = {
        enable = true;
        editor = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = false;
      timeout = 5;
    };

    initrd = {
      kernelModules = [
        "tg3"
      ];
      systemd.enable = true;
      systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
      systemd.network = {
        enable = true;
        wait-online.enable = false;
        networks."10-wired" = config.systemd.network.networks."10-wired";
      };
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = [
            "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIbfIla3NlPdru/+T7qvipOiI3ZcGBhrI6dWhZn6YFnnBuVfbeqoe7k/DAgqTQb9MLlRNIwXJHb/90cU/+7xXV8= sec-one@secretive"
          ];
          hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        };
      };
      luks.devices.cryptroot = {
        device = "/dev/disk/by-uuid/6ecacace-e05b-4d4c-b65a-7a1267a5615c";
        allowDiscards = true;
      };
    };
  };
}
