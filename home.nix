{ config, pkgs, ... }:

{
  # TODO please change the username & home directory to your own
  home.username = "vlp";
  home.homeDirectory = "/home/vlp";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    cowsay
  ];

  # basic configuration of git, please change to your own
  programs.git = {
    enable = true;
    userName = "vlp";
    userEmail = "vlp@fdn.fr";
    signing = {
      key = "11E97E99EFF47CD9EA7445D4AB8B02134A7467D2";
      signByDefault = true;
    };
    extraConfig = {
      core = {
      editor ="vim";
     	};
    };
  };

  # starship - an customizable prompt for any shell
  programs.starship = {
    enable = true;
    # custom settings
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  # alacritty - a cross-platform, GPU-accelerated terminal emulator
  programs.alacritty = {
    enable = true;
    # custom settings
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
    '';
    shellAliases = {
      fr = "sudo nixos-rebuild switch --flake /home/vlp/nixos_maison";
      scanit = "scanimage --format=jpeg --resolution=300 --mode Color -p > /home/vlp/partages/scan.jpg";
    };
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
