{ pkgs, pkgs-unstable, ... }:

{
  home.packages = with pkgs; [
    # Essential kubernetes tools
    kubectl
    kubernetes-helm
    kubectx
    k9s
    kind # Kubernetes in Docker - local clusters
    argocd # ArgoCD CLI — pinned to 2.12.x to match server version

    # Infrastructure as Code
    terraform
    terraform-docs
    terragrunt
    hcl2json # Convert HCL to JSON for easier processing

    # Nix development tools
    nil # Nix language server
    nixfmt # Nix formatter (RFC style is now the default upstream)
    nixpkgs-fmt # Alternative Nix formatter for pre-commit
    deadnix # Dead code elimination for Nix
    statix # Nix linter

    # Cloud tools
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    awscli2 # AWS CLI v2
    grafana # Includes grafana-cli
    grafana-loki # Includes logcli for querying Loki

    # Python environment
    (pkgs.python3.withPackages (python-pkgs: [
      # nixpkgs 26.05 still ships pipx 1.8.0, whose own test suite fails against the
      # `packaging` version in this release (fixed upstream in pipx 1.9.0, see
      # https://github.com/pypa/pipx/pull/1712). Bump the version/src to pick up that fix
      # rather than disabling the checks.
      (python-pkgs.pipx.overridePythonAttrs (_old: {
        version = "1.9.0";
        src = pkgs.fetchFromGitHub {
          owner = "pypa";
          repo = "pipx";
          tag = "1.9.0";
          hash = "sha256-AeGa+JMXEfhfCLKuj+Q0zJdQas8bxszalutdWZKf0sM=";
        };
      }))
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

    # OX Security CLI (oxappsec.com)
    (pkgs.stdenv.mkDerivation rec {
      pname = "ox-cli";
      version = "0.53.2";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@oxappsec/ox-cli/-/ox-cli-${version}.tgz";
        hash = "sha256-mwC99DQKcCQvojqY4SSM3U2Ow8ZK4Nii+R/BeRsGXTA=";
      };
      nativeBuildInputs = [ pkgs.makeWrapper ];
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/lib/ox-cli $out/bin
        cp -r . $out/lib/ox-cli/
        makeWrapper ${pkgs.nodejs}/bin/node $out/bin/ox-cli \
          --add-flags "$out/lib/ox-cli/bundle.js"
      '';
      meta = {
        description = "CLI tool for OX Security";
        mainProgram = "ox-cli";
      };
    })
  ];
}
