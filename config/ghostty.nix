{ pkgs, ... }:

{
  # Ghostty terminal configuration
  home.file.".config/ghostty/config".text = ''
    # Font settings
    font-family = "MesloLGS NF"
    font-size = 14

    # Performance and responsiveness
    scrollback-limit = 100000
    cursor-style = block
    cursor-style-blink = false

    # Speed up scrolling
    mouse-scroll-multiplier = 3

    # Theme
    background-opacity = 0.95

    # Shell integration
    shell-integration = zsh
    shell-integration-features = cursor,sudo,title
  '';
}
