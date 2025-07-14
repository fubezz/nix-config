{ pkgs, ... }:

{
  # Import all configuration modules
  imports = [
    ./ghostty.nix
    ./vscode.nix
  ];
}
