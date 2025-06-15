_:

let
  userConfig = import ./user.nix;
in
{
  # Import modular configurations
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/vscode.nix
    ./modules/macos.nix
  ];

  # Basic home-manager configuration
  home = {
    username = userConfig.user.name;
    inherit (userConfig.user) homeDirectory;
    stateVersion = "25.05"; # Please read the comment before changing.

    # Session variables
    sessionVariables = {
      EDITOR = "code --wait";
      VISUAL = "code --wait";
      GIT_EDITOR = "code --wait";
      PAGER = "less -R";
      LESS = "-R";
    };
  };

  # Enable home-manager
  programs.home-manager.enable = true;
}
