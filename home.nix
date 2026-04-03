{ self, config, pkgs, ... }:

{
  home.username = "vlp";
  home.homeDirectory = "/home/vlp";

  home.packages = with pkgs; [
    # home package list
  ];

  home.file.gpgSshKeys = {
    target = ".gnupg/sshcontrol";
    text = ''
      5A3BF9A2FFE564CE02AE8DBB7721B2B766C4D83B 600
    '';
  };

  programs.git = {
    enable = true;
    signing = {
      key = "11E97E99EFF47CD9EA7445D4AB8B02134A7467D2";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "vlp";
        email = "vlp@fdn.fr";
      };
      core = {
        editor = "vim";
      };
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
        draw_bold_text_with_bright_colors = true;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
    '';
    shellAliases = {
      fr = "sudo nixos-rebuild switch --flake /home/vlp/nixos_maison";
      frd = "sudo nixos-rebuild dry-activate --flake /home/vlp/nixos_maison";
      scanit = "sudo scanimage --format=png --resolution=300 --mode Color -p > /home/vlp/partages/scan.png";
      laptop = "ssh 192.168.101.13";
      botbot = "ssh 192.168.101.17";
      gateway-fdn = "ssh 192.168.101.18";
      new-dl = "ssh 192.168.101.12";
      webserver = "ssh 192.168.101.11";
    };
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
