_:

{
  # Configure macOS defaults for optimal development experience
  targets.darwin.defaults = {
    NSGlobalDomain = {
      # Set key repeat rate to fastest (1 = fastest, 2 = fast)
      KeyRepeat = 1;
      # Set initial key repeat delay to shortest (10 = very short delay)
      InitialKeyRepeat = 10;
      # Disable natural scrolling
      "com.apple.swipescrolldirection" = false;
      # Enable full keyboard access for all controls
      AppleKeyboardUIMode = 3;
      # Disable press-and-hold for keys in favor of key repeat
      ApplePressAndHoldEnabled = false;
    };

    dock = {
      # Auto-hide the dock
      autohide = true;
      # Remove the auto-hiding delay
      autohide-delay = 0.0;
      # Remove the animation when hiding/showing the Dock
      autohide-time-modifier = 0.0;
      # Show only open applications in the Dock
      static-only = true;
    };

    finder = {
      # Show all filename extensions
      AppleShowAllExtensions = true;
      # Show path bar
      ShowPathbar = true;
      # Show status bar
      ShowStatusBar = true;
    };
  };
}
