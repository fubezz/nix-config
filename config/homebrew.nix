{ ... }:

{
  homebrew = {
    enable = true;
    casks = [
      "container" # Apple's container tool for creating and running Linux containers
      "ghostty" # Modern terminal emulator
      "visual-studio-code" # Always latest version via homebrew
      "microsoft-teams" # Microsoft Teams
      "slack"
      "stats" # System monitoring app
      "marta" # File manager
      # "git-credential-manager" # Git credential management
    ];
    taps = [
      "atlassian/homebrew-acli"
    ];
    brews = [
      "pre-commit" # Git hooks framework - moved from nix due to dotnet issues
      "mise" # Tool for managing environments - moved from nix for newer version
      "atlassian/homebrew-acli/acli" # Atlassian CLI v2
      "pinentry-mac" # GPG pinentry for macOS
      "direnv" # Per-directory env vars - moved from nix due to fish test sandbox kill on macOS
      "rtk" # RTK CLI
    ];
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
