{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./modules/hardened-services.nix
    ./modules/ssh-inhibit-suspend.nix
    ./users/roman/linux-base.nix
  ];

  environment.systemPackages = import ./packages.nix {
    inherit pkgs config;
    isLinux = true;
  };

  boot.tmp.cleanOnBoot = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };

    optimise = {
      automatic = true;
      dates = "weekly";
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  users.users.root.openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
}
