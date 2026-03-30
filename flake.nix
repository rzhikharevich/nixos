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
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:MrSom3body-contrib/stylix/c52a700223cb2cfa1fb42b9de84887c72eb98825";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake.url = "github:sodiboo/niri-flake";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:rzhikharevich/microvm.nix/cloud-hv-notify-proxy-fix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    virby = {
      url = "github:quinneden/virby-nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin_exec = {
      url = "github:rzhikharevich/darwin_exec";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    revisor = {
      url = "github:rzhikharevich/revisor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin_darkmode = {
      url = "github:rzhikharevich/darwin_darkmode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-hardware,
      nix-darwin,
      home-manager,
      stylix,
      niri-flake,
      fenix,
      microvm,
      virby,
      darwin_exec,
      darwin_darkmode,
      revisor,
      ...
    }:
    let
      lib = import ./lib { inherit inputs; };

      commonOverlays = [
        fenix.overlays.default
        (import ./overlays.nix { inherit inputs; })
      ];

      nixosOverlays = [
        niri-flake.overlays.niri
      ]
      ++ commonOverlays;

      commonNixosModules = [
        ./configuration.nix
        ./linux.nix
        home-manager.nixosModules.default
        microvm.nixosModules.host
        ./modules/microvm-linux.nix
      ];

      commonDarwinModules = [
        ./configuration.nix
        ./darwin.nix
        home-manager.darwinModules.default
        virby.darwinModules.default
      ];

      mkHost =
        hostModule: extraModules:
        lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            isLinux = true;
            isDarwin = false;
          };
          modules = [
            { nixpkgs.overlays = nixosOverlays; }
          ]
          ++ commonNixosModules
          ++ [ hostModule ]
          ++ extraModules;
        };

      mkDarwinHost =
        hostModule: extraModules:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs self;
            isLinux = false;
            isDarwin = true;
          };
          modules = [
            { nixpkgs.overlays = commonOverlays; }
          ]
          ++ commonDarwinModules
          ++ [ hostModule ]
          ++ extraModules;
        };
    in
    {
      packages.x86_64-linux.default = fenix.packages.x86_64-linux.minimal.toolchain;

      nixosConfigurations.nixform = mkHost ./hosts/nixform [
        nixos-hardware.nixosModules.minisforum-v3
        nixos-hardware.nixosModules.common-cpu-amd-zenpower
        niri-flake.nixosModules.niri
        stylix.nixosModules.stylix
      ];

      darwinConfigurations.secretive = mkDarwinHost ./hosts/secretive [
        ./modules/microvm-darwin.nix
      ];
    };
}
