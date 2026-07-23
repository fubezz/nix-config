{ lib, ... }:

{
  # Configure macOS defaults for optimal development experience
  targets.darwin.defaults = {
    NSGlobalDomain = {
      # Set key repeat rate to fastest (1 = fastest, 2 = fast)
      KeyRepeat = 2;
      # Set initial key repeat delay to shortest (10 = very short delay)
      InitialKeyRepeat = 20;
      # Disable natural scrolling
      "com.apple.swipescrolldirection" = true;
      # Enable full keyboard access for all controls
      AppleKeyboardUIMode = 3;
      # Disable press-and-hold for keys in favor of key repeat
      ApplePressAndHoldEnabled = false;
    };

    # "com.apple.dock" = {
    #   # Keep the dock always visible
    #   autohide = false;
    #   # Show only open applications in the Dock
    #   static-only = false;
    # };

    "com.apple.finder" = {
      # Show all filename extensions
      AppleShowAllExtensions = true;
      # Show path bar
      ShowPathbar = true;
      # Show status bar
      ShowStatusBar = true;
    };
  };

  # `defaults import` (run by setDarwinDefaults) only writes the plist — it doesn't
  # tell the running Dock/Finder to reload it, so restart them to pick up changes.
  home.activation.restartDockAndFinder = lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
    run /usr/bin/killall Dock Finder 2>/dev/null || true
  '';
}
