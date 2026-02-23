{
  inputs = {
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
  outputs = inputs@{ self, nixpkgs, nixos-hardware, home-manager, stylix, niri-flake, ... }: {
    nixosConfigurations.nixform = nixpkgs.lib.nixosSystem {
      modules = [
        { nixpkgs.overlays = [ niri-flake.overlays.niri ]; }
        ./configuration.nix
        home-manager.nixosModules.default
        niri-flake.nixosModules.niri
        nixos-hardware.nixosModules.minisforum-v3
        stylix.nixosModules.stylix
      ];
    };
  };
}
