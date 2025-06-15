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
  ];
}
