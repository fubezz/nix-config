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
        ];
      };
      
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      l = "ls -lAh";
      g = "git";
      k = "kubectl";
      k9s = "k9s";
      tf = "terraform";
      tg = "terragrunt";
      glogin = "gcloud auth application-default login";
      nixrb = "sudo darwin-rebuild switch --flake . --impure";
    };
    sessionVariables = {
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border";
    };
    initContent = ''
      source /etc/aignostics/
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "kubectl" "python" "uv" ];
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
    };
  };
}

