{ config, lib, pkgs, ... }:

{
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
}
