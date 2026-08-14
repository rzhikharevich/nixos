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
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    virby = {
      url = "github:rzhikharevich/virby-nix-darwin";
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
    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    foundryvtt = {
      url = "github:rzhikharevich/nix-foundryvtt";
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
      nixos-apple-silicon,
      foundryvtt,
      ...
    }:
    let
      lib = import ./lib { inherit inputs; };

      # Fenix still reads the deprecated stdenv platform aliases. Keep those
      # aliases warning-free while the dependency is evaluated.
      fenixPlatformCompatibility = _final: prev: {
        stdenv = prev.stdenv // {
          isLinux = prev.stdenv.hostPlatform.isLinux;
          isDarwin = prev.stdenv.hostPlatform.isDarwin;
        };
      };

      commonOverlays = [
        fenixPlatformCompatibility
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
      ];

      commonDarwinModules = [
        ./configuration.nix
        ./darwin.nix
        ./modules/kanata.nix
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
            inherit inputs self lib;
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
      packages.x86_64-linux.default =
        (import nixpkgs {
          system = "x86_64-linux";
          overlays = commonOverlays;
        }).fenix.minimal.toolchain;

      nixosConfigurations.nixform = mkHost ./hosts/nixform [
        nixos-hardware.nixosModules.minisforum-v3
        nixos-hardware.nixosModules.common-cpu-amd-zenpower
        niri-flake.nixosModules.niri
        stylix.nixosModules.stylix
        microvm.nixosModules.host
        ./modules/microvm-linux.nix
        ./modules/desktop.nix
        ./modules/pam-no-fprint.nix
        ./modules/kanata.nix
        ./users/greeter/default.nix
        ./users/roman/linux.nix
      ];

      nixosConfigurations.nixodrome = mkHost ./hosts/nixodrome [
        nixos-apple-silicon.nixosModules.apple-silicon-support
        foundryvtt.nixosModules.foundryvtt
        inputs.sops-nix.nixosModules.sops
        microvm.nixosModules.host
        ./modules/microvm-linux.nix
      ];

      darwinConfigurations.secretive = mkDarwinHost ./hosts/secretive [
        ./modules/microvm-darwin.nix
      ];

      darwinConfigurations.tenserise = mkDarwinHost ./hosts/tenserise [
        ./modules/microvm-darwin.nix
      ];
    };
}
