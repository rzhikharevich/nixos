{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./users/roman/darwin.nix
  ];

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  security.pam.services.sudo_local.touchIdAuth = true;
}
