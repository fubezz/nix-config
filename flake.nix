{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nix-darwin
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , nix-homebrew
    , mac-app-util
    , nix-vscode-extensions
    , ...
    }:

    let
      userConfig = import ./user.nix;
      machineConfig = {
        system = userConfig.system.platform;
        inherit (userConfig.system) hostname;
        username = userConfig.user.name;
        home = userConfig.system.homeDirectory;
        homeManager.stateVersion = "25.05";
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit (machineConfig) system;
        config = {
          allowUnfree = true;
        };
      };
      pkgs = import nixpkgs {
        overlays = [
          nix-vscode-extensions.overlays.default
          (final: prev: {
            git-credential-manager = pkgs-unstable.git-credential-manager;
            pre-commit = pkgs-unstable.pre-commit;
          })
        ];
        inherit (machineConfig) system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
          #allowBroken = true;
          allowInsecure = false;
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#MacBook-Pro
      darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
        inherit (machineConfig) system;
        inherit pkgs;
        modules = [
          ./configuration.nix

          mac-app-util.darwinModules.default

          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${userConfig.user.name} = import ./home.nix;
              # To enable spotlight for all users:
              sharedModules = [
                mac-app-util.homeManagerModules.default
              ];
            };
          }

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;
              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;
              # User owning the Homebrew prefix
              user = userConfig.user.name;
              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };
          }
        ];
      };
    };
}
