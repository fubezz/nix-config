{ ... }:

{
  programs.gpg = {
    enable = true;
    settings = {
      no-tty = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    extraConfig = ''
      allow-loopback-pinentry
      pinentry-program /opt/homebrew/bin/pinentry-mac
    '';
  };
}
