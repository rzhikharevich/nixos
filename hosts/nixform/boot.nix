{
  pkgs,
  lib,
  ...
}:

{
  boot = {
    kernelParams = [
      # TODO: Test amd_pstate=passive with manually set minimum frequencies (which default to the
      # min non-linear frequency = ~1100 MHz, not the absolute minimum = ~400 MHz which is what
      # active does in power-saving mode).
      "amd_pstate=active"

      # Experiment: Assign IRQs to boot CPU cores + cores with the highest amd_pstate_prefcore_ranking
      # which pairs well with scx_lavd since it tries to pack threads on the latter (the boot core
      # can't be prevented from receiving IRQs).
      "irqaffinity=0,1,8,9"

      # Micro-benchmarking:
      # "isolcpus=4,12"
      # "nohz_full=4,12"

      # threadirqs is interesting since it would presumably bring IRQs under lavd's control but
      # it's probably more trouble (overhead) than it's worth.

      # Lockup watchdogs are not that relevant on laptops unless I'll have to debug kernel bugs
      # (hopefully not).
      "nowatchdog"

      # Enabling this makes the per-cpu workqueues which
      # were observed to contribute significantly to power
      # consumption unbound, leading to measurably lower
      # power usage at the cost of small performance
      # overhead.
      #   - https://docs.kernel.org/admin-guide/kernel-parameters.html
      "workqueue.power_efficient=1"

      # rcutree.enable_rcu_lazy allows the kernel to delay RCU callbacks to decrease the amount of
      # RCU grace periods and therefore let idle CPUs sleep for longer. rcu_nocbs= is required for
      # it to work on a given CPU, enable it for all.
      #   - https://lwn.net/Articles/988638
      "rcutree.enable_rcu_lazy=1"
      "rcu_nocbs=all"

      # PCIe ASPM might be negotiated to be off by the BIOS for spurious reasons, force enable it.
      #   - https://wireless.docs.kernel.org/en/latest/en/users/documentation/aspm.html
      #
      # Note that pcie_aspm.policy is already set to powersupersave by nixos-hardware.
      "pcie_aspm=force"
    ];
    extraModprobeConfig = ''
      options iwlwifi power_save=1 uapsd_disable=0
      options iwlmvm power_scheme=3
    '';
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
    };
    initrd = {
      systemd.enable = true;
      luks.devices.cryptroot = {
        device = "/dev/disk/by-uuid/7dc4136d-c383-4971-95f6-bbcbb74fe4a1";
        preLVM = true;
        allowDiscards = true;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl."vm.dirty_writeback_centisecs" = 1500;
  };

  environment.etc."lvm/lvm.conf".text = lib.mkForce ''
    devices {
      issue_discards = 1
    }
  '';
}
