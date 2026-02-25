{
   nixConfig = {
      extra-substituters = [
         "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
         "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
   };

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
    fenix = {
       url = "github:nix-community/fenix";
       inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, nixos-hardware, home-manager, stylix, niri-flake, fenix, ... }: {
    packages.x86_64-linux.default = fenix.packages.x86_64-linux.minimal.toolchain;
    nixosConfigurations.nixform = nixpkgs.lib.nixosSystem {
      modules = [
        { nixpkgs.overlays = [ niri-flake.overlays.niri fenix.overlays.default ]; }
        ./configuration.nix
        home-manager.nixosModules.default
        niri-flake.nixosModules.niri
        nixos-hardware.nixosModules.minisforum-v3
        stylix.nixosModules.stylix
      ];
    };
  };
}
