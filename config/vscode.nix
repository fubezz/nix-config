{ pkgs, ... }:

{
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
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
        "editor.rulers" = [ 80 120 ];
        "editor.minimap.enabled" = false;
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = "active";
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "workbench.editor.enablePreview" = false;
        "explorer.confirmDelete" = false;
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "terminal.integrated.fontSize" = 12;
        "terminal.integrated.fontFamily" = "MesloLGS NF";

        # Nix-specific settings
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.tabSize" = 2;
          "editor.formatOnSave" = true;
        };
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {
              "command" = [ "nixpkgs-fmt" ];
            };
            "diagnostics" = {
              "ignored" = [ "unused_binding" "unused_with" ];
            };
          };
        };

        # File associations
        "files.associations" = {
          "*.nix" = "nix";
          "flake.lock" = "json";
          "*.hcl" = "terraform";
          "terragrunt.hcl" = "terraform";
          "*.terragrunt" = "terraform";
        };

        # Terraform-specific settings
        "terraform.experimentalFeatures.validateOnSave" = true;
        "terraform.experimentalFeatures.prefillRequiredFields" = true;
        "[terraform]" = {
          "editor.defaultFormatter" = "hashicorp.terraform";
          "editor.formatOnSave" = true;
          "editor.tabSize" = 2;
          "editor.insertSpaces" = true;
        };
        "[terraform-vars]" = {
          "editor.defaultFormatter" = "hashicorp.terraform";
          "editor.formatOnSave" = true;
          "editor.tabSize" = 2;
          "editor.insertSpaces" = true;
        };

      };

      extensions = with pkgs.vscode-marketplace; [
        # Nix development
        jnoortheen.nix-ide # Main Nix language support
        bbenoist.nix # Additional Nix language support
        arrterian.nix-env-selector # Nix environment selector
        pinage404.nix-extension-pack # Nix extension pack

        # Theme
        dracula-theme.theme-dracula

        # Language support
        redhat.vscode-yaml
        hashicorp.terraform
        ms-python.python
        ms-python.black-formatter
        ms-python.isort
        ms-python.flake8 # Python linting
        tamasfe.even-better-toml

        # DevOps and cloud tools
        ms-kubernetes-tools.vscode-kubernetes-tools

        # Git integration
        eamodio.gitlens
      ];
    };
  };
}
