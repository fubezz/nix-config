{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Essential kubernetes tools
    kubectl
    kubernetes-helm
    k9s
    kind # Kubernetes in Docker - local clusters
    argocd # ArgoCD CLI

    # Infrastructure as Code
    terraform
    terragrunt

    # Nix development tools
    nil # Nix language server
    nixfmt-rfc-style # Nix formatter
    nixpkgs-fmt # Alternative Nix formatter for pre-commit
    deadnix # Dead code elimination for Nix
    statix # Nix linter

    # Cloud tools
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])

    # Python environment
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.pipx
    ]))

    # Go programming language
    go

    # Shell and terminal tools
    oh-my-zsh
    fzf
    fd
    pre-commit # Git hooks framework

    # Enhanced CLI tools
    ripgrep # Fast grep alternative
    bat # Better cat with syntax highlighting
    eza # Better ls with colors and git status (exa replacement)
    tree # Directory tree visualization
    jq # JSON processor
    yq # YAML processor
    htop # Better top
    diff-so-fancy # Better git diff
    gh # GitHub CLI
    lazygit # Terminal UI for git
    direnv # Per-directory environment variables
    go-task # For task management

    # Pre-commit and code quality tools
    gitlint # Git commit message linter
    detect-secrets # Secret detection tool

    # Additional development tools
    neovim # Modern vim-based editor
    micro
    curl # HTTP client
    wget # File downloader
    rsync # File synchronization
    unzip # Archive extraction
    zip # Archive creation

    # Network and system tools
    nmap # Network scanner
    netcat # Network utility
    watch # Command monitoring
    lsof # List open files
    ps # Process status

    # Development utilities
    shellcheck # Shell script linting
    yamllint # YAML linting
    pre-commit # Git pre-commit hooks
    go-task # Task runner / build tool alternative to Make
    uv

    # Container tools
    dive # Docker image analysis
    docker # docker runtime
    colima # docker desktop for terminal

    # Git tools
    git-lfs # Git Large File Storage
    git-crypt # Git encryption
    tig # Text-mode interface for git
    git-credential-manager # Git credential management
    gnupg # GPG for commit signing

    # JSON/YAML tools
    fx # JSON viewer
    dasel # JSON/YAML/TOML/XML processor
  ];
}
