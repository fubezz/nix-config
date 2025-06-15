{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Container and orchestration tools
    podman
    kubectl
    kubernetes-helm
    k9s

    # Infrastructure as Code
    terraform
    terragrunt

    # Nix development tools
    nil           # Nix language server

    # Cloud tools
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])

    # Python environment
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.pipx
    ]))

    # Shell and terminal tools
    oh-my-zsh
    fzf
    fd

    # Enhanced CLI tools
    ripgrep       # Fast grep alternative
    bat           # Better cat with syntax highlighting
    eza           # Better ls with colors and git status (exa replacement)
    tree          # Directory tree visualization
    jq            # JSON processor
    yq            # YAML processor
    htop          # Better top
    diff-so-fancy # Better git diff
    gh            # GitHub CLI
    lazygit       # Terminal UI for git
    direnv        # Per-directory environment variables

    # Additional development tools
    neovim        # Modern vim-based editor
    curl          # HTTP client
    wget          # File downloader
    rsync         # File synchronization
    unzip         # Archive extraction
    zip           # Archive creation

    # Network and system tools
    nmap          # Network scanner
    netcat        # Network utility
    watch         # Command monitoring
    lsof          # List open files
    ps            # Process status

    # Development utilities
    shellcheck    # Shell script linting
    yamllint      # YAML linting
    pre-commit    # Git pre-commit hooks

    # Container tools
    dive          # Docker image analysis

    # Git tools
    git-lfs       # Git Large File Storage
    git-crypt     # Git encryption
    tig           # Text-mode interface for git

    # JSON/YAML tools
    fx            # JSON viewer
    dasel         # JSON/YAML/TOML/XML processor
  ];
}
