{ pkgs, pkgs-unstable, pkgs-2411, ... }:

{
  home.packages = with pkgs; [
    # Essential kubernetes tools
    kubectl
    kubernetes-helm
    kubectx
    k9s
    kind # Kubernetes in Docker - local clusters
    pkgs-2411.argocd # ArgoCD CLI — pinned to 2.12.x to match server version

    # Infrastructure as Code
    terraform
    terraform-docs
    terragrunt
    hcl2json # Convert HCL to JSON for easier processing

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
    awscli2 # AWS CLI v2

    # Python environment
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.pipx
    ]))

    # Go programming language
    go

    # Node.js (includes npm and npx)
    nodejs

    # Shell and terminal tools
    oh-my-zsh
    fzf
    fd
    # pre-commit - moved to homebrew due to dotnet dependency issues

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
    # direnv - moved to homebrew due to fish test sandbox kill on macOS
    go-task # For task management

    # Pre-commit and code quality tools
    gitlint # Git commit message linter
    detect-secrets # Secret detection tool
    trivy # Vulnerability scanner for containers and files

    # Additional development tools
    neovim # Modern vim-based editor
    micro
    curl # HTTP client
    wget # File downloader
    rsync # File synchronization
    unzip # Archive extraction
    zip # Archive creation
    sipcalc # IP calculator

    # Network and system tools
    nmap # Network scanner
    netcat # Network utility
    pwgen # Password generator
    watch # Command monitoring
    lsof # List open files
    ps # Process status

    # Development utilities
    shellcheck # Shell script linting
    yamllint # YAML linting
    # pre-commit - moved to homebrew due to dotnet dependency issues
    go-task # Task runner / build tool alternative to Make
    uv # Universal command-line interface for running commands
    # open-policy-agent # Open Policy Agent for policy enforcement
    conftest # Policy testing tool
    # mise - moved to homebrew for newer version

    # Container tools
    dive # Docker image analysis
    docker_29 # docker runtime (docker_28 marked insecure)
    pkgs-unstable.colima # docker desktop for terminal (stable lima is EOL in 25.11)

    # Git tools
    git-lfs # Git Large File Storage
    git-crypt # Git encryption
    tig # Text-mode interface for git
    # git-credential-manager # Disabled - uses dotnet which is broken, using osxkeychain instead
    gnupg # GPG for commit signing

    # JSON/YAML tools
    fx # JSON viewer
    dasel # JSON/YAML/TOML/XML processor

    # Ai
    pkgs-unstable.claude-code # Anthropic Claude CLI (from unstable)

    # OpenSpec CLI - spec-driven development tool (openspec.dev / github.com/Fission-AI/OpenSpec)
    # Installs the `openspec` binary; run `openspec init` in a repo, `openspec update` to sync skills
    (pkgs.buildNpmPackage rec {
      pname = "openspec";
      version = "1.4.1";
      src = pkgs.fetchFromGitHub {
        owner = "Fission-AI";
        repo = "OpenSpec";
        rev = "v${version}";
        hash = "sha256-VZZ/ukjciXqiebwei2JizyOnxx0T3IeoowFWElKec4o=";
      };
      nativeBuildInputs = [ pkgs.pnpm ];
      npmDepsHash = "sha256-vGD8rZgqcgIKOAQTuZVHh6C+QTrxkyw9CgdJ4NOwSp8=";
      meta = {
        description = "AI-native system for spec-driven development";
        homepage = "https://github.com/Fission-AI/OpenSpec";
        license = pkgs.lib.licenses.mit;
        mainProgram = "openspec";
      };
    })
  ];
}
