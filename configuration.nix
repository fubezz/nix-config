{ lib, pkgs, ... }:

let
  userConfig = import ./user.nix;
in
{

  system.primaryUser = userConfig.user.name;
  users.users.${userConfig.user.name} = {
    inherit (userConfig.user) name;
    home = userConfig.user.homeDirectory;
  };
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # Essential system tools
    gitAndTools.gitFull
    nmap
    rectangle

    # Mac-specific tools
    mas # Mac App Store CLI
    dockutil # Dock management
  ];


  # Necessary for using flakes on this system.
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      # Disable channels to avoid search path warnings
      use-xdg-base-directories = true;
      # Prevent looking for channels
      nix-path = lib.mkForce [ ];
    };

    # Use the proper way to enable store optimization on macOS
    optimise.automatic = true;

    # Disable channels completely since we're using flakes
    channel.enable = false;
  };
  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = userConfig.system.platform;
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Homebrew configuration
  homebrew = {
    enable = true;
    casks = [
      "container" # Apple's container tool for creating and running Linux containers
      "ghostty" # Modern terminal emulator
      "microsoft-teams" # Microsoft Teams
      "slack"
      "stats" # System monitoring app
      "marta" # File manager
    ];
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
