{ pkgs, ... }:

{
  programs = {
    zsh = {
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
        gd = "git diff";
        gb = "git branch";
        gco = "git checkout";
        glg = "git log --graph --oneline --decorate";

        # Kubernetes aliases
        k = "kubectl";
        k9s = "k9s";
        kgp = "kubectl get pods";
        kgs = "kubectl get services";
        kgd = "kubectl get deployments";

        # Infrastructure aliases
        tf = "terraform";
        tg = "terragrunt";
        tfi = "terraform init";
        tfp = "terraform plan";
        tfa = "terraform apply";

        # Cloud aliases
        glogin = "gcloud auth application-default login";

        # System aliases
        nixrb = "sudo darwin-rebuild switch --flake . --impure";
        cat = "bat";
        grep = "rg";
        find = "fd";
        ps = "procs";
        top = "btm";
        du = "dust";

        # Useful shortcuts
        cls = "clear";
        reload = "source ~/.zshrc";
        edit = "code";
        vim = "nvim";
        vi = "nvim";

        # Network utilities
        ports = "lsof -i -P -n | grep LISTEN";
        myip = "curl -s https://httpbin.org/ip | jq -r .origin";
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
        plugins = [ "git" "kubectl" "python" "uv" "direnv" ];
        theme = "robbyrussell";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    git = {
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
  };

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
    theme = dark
    background-opacity = 0.95

    # Shell integration
    shell-integration = zsh
    shell-integration-features = cursor,sudo,title
  '';
}
