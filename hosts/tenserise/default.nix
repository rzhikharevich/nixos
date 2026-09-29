{ ... }:

{
  networking.hostName = "tenserise";

  nixpkgs.hostPlatform = "aarch64-darwin";

  services.virby = {
    cores = 12;
    memory = 32768;
  };

  system.stateVersion = 6;
}
