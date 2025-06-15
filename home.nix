{ config, lib, pkgs, ... }:

{
  # Import modular configurations
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/vscode.nix
    ./modules/macos.nix
  ];

  # Basic home-manager configuration
  home.username = "fabian";
  home.homeDirectory = "/Users/fabian";
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # Session variables
  home.sessionVariables = {
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    GIT_EDITOR = "code --wait";
    PAGER = "less -R";
    LESS = "-R";
  };

  # Enable home-manager
  programs.home-manager.enable = true;
}

