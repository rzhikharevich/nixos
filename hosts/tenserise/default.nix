{ ... }:

{
  networking.hostName = "tenserise";

  nixpkgs.hostPlatform = "aarch64-darwin";

  services.virby = {
    cores = 12;
    memory = 32768;
  };

  homebrew.casks = [
    "orbstack"
    "postgres-app"
  ];

  users.users.roman.openssh.authorizedKeys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBwxpC2XM9Ialnbm51C5UCIW2ih9+tTBzkjWUc2Fv9ORFw4XCeTLSwHLQt+hLD5fm8E5lnF9QxV1Jt8/851jIyk= ShellFish@iPhone-Enclave-03022026"
  ];

  system.stateVersion = 6;
}
