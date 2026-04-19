{
  config,
  pkgs,
  ...
}:

{
  users.users.roman = {
    uid = if config.networking.hostName == "nixodrome" then 1001 else 1000;
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
  };

  home-manager.users.roman = {
    imports = [
      ./shared.nix
    ];
  };
}
