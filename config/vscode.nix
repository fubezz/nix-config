{ pkgs, lib, ... }:

let
  codeExe = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code";
  extensions = [
    # Theme
    "dracula-theme.theme-dracula"

    # Language support
    "jnoortheen.nix-ide"
    "redhat.vscode-yaml"
    "bahramjoharshamshiri.hcl-lsp"
    "hashicorp.terraform"
    "ossamatammam.terragrunt-formatter"
    "tsandall.opa" # Open Policy Agent

    # Data
    "mechatroner.rainbow-csv"

    # Git integration
    "eamodio.gitlens"
    "mhutchie.git-graph"
    "github.vscode-github-actions"

    # Kubernetes / Helm
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "technosophos.vscode-helm"
    "tim-koehler.helm-intellisense"
  ];
in
{
  programs.vscode = {
    enable = true;
    # Use homebrew-installed VSCode (always latest) instead of the pinned nixpkgs version.
    # The wrapper provides the `code` CLI pointing to the homebrew app.
    package = (pkgs.writeScriptBin "code" ''
      exec "${codeExe}" "$@"
    '').overrideAttrs (_: {
      pname = "vscode";
      version = "0.0.0";
    });
    mutableExtensionsDir = true;

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
        "git.autofetch" = false;
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
          "*.hcl" = "terragrunt";
          "terragrunt.hcl" = "terragrunt";
          "*.terragrunt" = "terragrunt";
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

        # Terragrunt-specific settings
        "[terragrunt]" = {
          "editor.defaultFormatter" = "ossamatammam.terragrunt-formatter";
          "editor.formatOnSave" = true;
          "editor.tabSize" = 2;
          "editor.insertSpaces" = true;
        };
      };
    };
  };

  # Install extensions via code CLI so VSCode can update them freely.
  # Skips extensions that are already installed at any version.
  home.activation.installVSCodeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x "${codeExe}" ]; then
      for ext in ${lib.concatStringsSep " " extensions}; do
        "${codeExe}" --install-extension "$ext" 2>/dev/null || true
      done
    fi
  '';
}
