{ config, lib, pkgs, ... }:

{
  home.username = "fabian";
  home.homeDirectory = "/Users/fabian";
  home.stateVersion = "25.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    podman
    kubectl
    kubernetes-helm
    k9s
    terraform
    terragrunt
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.pipx
    ]))
    oh-my-zsh
    fzf
    fd
    # Additional useful tools
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
  #home.file = {};
  home.sessionVariables = {
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    GIT_EDITOR = "code --wait";
    PAGER = "less -R";
    LESS = "-R";
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Fabin Spiess";
    userEmail = "fabian@aignostics.com";
    extraConfig = {
      github.user = "fubezz";
      init = { defaultBranch = "develop"; };
      diff = { external = "${pkgs.difftastic}/bin/difft"; };
      pull = { rebase = true; };
      push = { autoSetupRemote = true; };
      core = { editor = "code --wait"; };
    };
  };

  programs.vscode = {
      enable = true; 
      profiles.default = {
        keybindings = [
        # See https://code.visualstudio.com/docs/getstarted/keybindings#_advanced-customization
          {
              key = "shift+cmd+j";
              command = "workbench.action.focusActiveEditorGroup";
              when = "terminalFocus";
          }
      ];
      userSettings = {
          # This property will be used to generate settings.json:
          # https://code.visualstudio.com/docs/getstarted/settings#_settingsjson
          "editor.formatOnSave" = true;
        };
        extensions = with pkgs.vscode-marketplace; [
          jnoortheen.nix-ide
          dracula-theme.theme-dracula
          # Additional useful extensions
          redhat.vscode-yaml
          hashicorp.terraform
          ms-kubernetes-tools.vscode-kubernetes-tools
          github.vscode-pull-request-github
          eamodio.gitlens
          ms-python.python
          ms-python.black-formatter
        ];
      };
      
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      # Enhanced ls aliases using eza
      ll = "eza -l --git";
      la = "eza -la --git";
      l = "eza -lah --git";
      ls = "eza";
      tree = "eza --tree";
      # Git aliases
      g = "git";
      gst = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      # Kubernetes aliases
      k = "kubectl";
      k9s = "k9s";
      # Infrastructure aliases
      tf = "terraform";
      tg = "terragrunt";
      # Cloud aliases
      glogin = "gcloud auth application-default login";
      # System aliases
      nixrb = "sudo darwin-rebuild switch --flake . --impure";
      cat = "bat";
      grep = "rg";
    };
    sessionVariables = {
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border";
    };
    initContent = ''
      source /etc/aignostics/
      # Enable direnv
      eval "$(direnv hook zsh)"
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "kubectl" "python" "uv" "direnv" ];
      theme = "robbyrussell";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Configure macOS defaults for fastest cursor speed
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

