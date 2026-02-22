{
  inputs = {
    # This is pointing to an unstable release.
    # If you prefer a stable release instead, you can this to the latest number shown here: https://nixos.org/download
    # i.e. nixos-24.11
    # Use `nix flake update` to update the flake to the latest revision of the chosen release channel.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake.url = "github:sodiboo/niri-flake";
  };
  outputs = inputs@{ self, nixpkgs, nixos-hardware, home-manager, niri-flake, ... }: {
    nixosConfigurations.nixform = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit niri-flake; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.default
        niri-flake.nixosModules.niri
        nixos-hardware.nixosModules.minisforum-v3
        stylix.nixosModules.stylix
      ];
    };
  };
}
