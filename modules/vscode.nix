{ config, lib, pkgs, ... }:

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
      };
      
      extensions = with pkgs.vscode-marketplace; [
        # Nix development
        jnoortheen.nix-ide
        
        # Theme
        dracula-theme.theme-dracula
        
        # Language support
        redhat.vscode-yaml
        hashicorp.terraform
        ms-python.python
        ms-python.black-formatter
        
        # DevOps and cloud tools
        ms-kubernetes-tools.vscode-kubernetes-tools
        
        # Git integration
        github.vscode-pull-request-github
        eamodio.gitlens
      ];
    };
  };
}
