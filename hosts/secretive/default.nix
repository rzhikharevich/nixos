{ ... }:

{
  networking.hostName = "secretive";

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 6;
}
