{ pkgs, ... }:

let
  userConfig = import ../user.nix;
in
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = userConfig.user.fullName;
        email = userConfig.user.email;
        signingkey = userConfig.git.signingKey;
      };
      github.user = userConfig.git.githubUsername;
      init = { inherit (userConfig.git) defaultBranch; };
      diff = { external = "${pkgs.difftastic}/bin/difft"; };
      pull = { rebase = true; };
      push = { autoSetupRemote = true; };
      core = { editor = "vim"; };
      credential = {
        helper = "osxkeychain";
      };
      commit = {
        gpgsign = true;
      };
      tag = {
        gpgsign = true;
      };
      gpg = {
        format = "openpgp";
        program = "${pkgs.gnupg}/bin/gpg2";
      };
    };
  };
}
