{ config, lib, pkgs, ... }:

{
  
  system.primaryUser = "fabian";
  users.users.fabian = {
    name = "fabian";
  	home = "/Users/fabian";
  };
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    neovim
    curl
    gitAndTools.gitFull
    nmap
    htop
    zellij
    micro
    rectangle
  ];


  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config = {
    allowUnfree = true;
  };
}
