{
  inputs,
  config,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
  ];

  sops.secrets = {
    roman-password = { };
  };

  networking = {
    hostId = "b0d86da2";
    hostName = "panther";
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

  environment.etc."machine-id".source = "/var/lib/machine-id";

  users = {
    mutableUsers = false;
    hashedPasswordFile = config.sops.secrets.roman-password.path;
  };

  system.stateVersion = "26.05";
}
