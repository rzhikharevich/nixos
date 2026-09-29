{ ... }:

{
  networking.hostName = "secretive";

  nixpkgs.hostPlatform = "aarch64-darwin";

  services.virby = {
    cores = 8;
    memory = 8192;
  };

  system.stateVersion = 6;
}
