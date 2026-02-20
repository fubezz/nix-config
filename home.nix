{ pkgs-unstable, ... }:

let
  userConfig = import ./user.nix;
in
{
  # Import modular configurations
  imports = [
    ./modules/packages.nix
    ./modules/macos.nix
    ./config # This imports all config modules via default.nix
  ];

  # Basic home-manager configuration
  home = {
    username = userConfig.user.name;
    inherit (userConfig.user) homeDirectory;
    stateVersion = "25.05"; # Please read the comment before changing.

    # Session variables
    sessionVariables = {
      PAGER = "less -R";
      LESS = "-R";
    };
  };

  # Enable home-manager
  programs.home-manager.enable = true;
}
