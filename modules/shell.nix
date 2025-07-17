{ pkgs, ... }:

let
  userConfig = import ../user.nix;
in
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

        # GPG aliases
        gpglist = "gpg --list-secret-keys --keyid-format=long";
        gpgsetkey = "git config user.signingkey";

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
        glogin = "gcloud auth login --update-adc";

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
        TERM = "xterm-256color";
        K9S_FEATURE_GATE_NODE_SHELL = true;
      };

      initContent = ''
        source /etc/aignostics/main.sh
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
      userName = userConfig.user.fullName;
      userEmail = userConfig.user.email;
      extraConfig = {
        github.user = userConfig.git.githubUsername;
        init = { inherit (userConfig.git) defaultBranch; };
        diff = { external = "${pkgs.difftastic}/bin/difft"; };
        pull = { rebase = true; };
        push = { autoSetupRemote = true; };
        core = { editor = "code --wait"; };

        # Credential management for GitHub
        credential = {
          "https://github.com" = {
            helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
          };
          helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
        };

        # GPG commit signing
        commit = {
          gpgsign = false;
        };
        tag = {
          gpgsign = false;
        };
        gpg = {
          format = "openpgp";
        };
      };
    };
  };
}
