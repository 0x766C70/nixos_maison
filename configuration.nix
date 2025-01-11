# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "maison"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  # Configure console keymap
  console.keyMap = "us-acentos";

  users.groups.mlc = {};

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.vlp = {
    isNormalUser = true;
    description = "vlp";
    extraGroups = [ "networkmanager" "wheel" "incus-admin" "mlc"];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlXpy4JAK6MQ6JOz/nGRblIYU6CO1PapIgL0SsFRk1C cardno:11_514_955" ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mlc = {
    isNormalUser = true;
    description = "mlc";
    group = "mlc";
    homeMode = "770"; 
    packages = with pkgs; [];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "vlp";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    
    # basic tools
    vim
    git
    nnn 
    zip
    xz
    unzip
    p7zip
    ripgrep 
    jq
    yq-go
    eza
    fzf
    incus

    # networking tools
    openvpn
    mtr
    iperf3
    dnsutils
    ldns 
    aria2
    socat
    nmap
    ipcalc
    curl
    wget

    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # productivity
    glow # markdown previewer in terminal

    # monitoring
    btop  # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors
    ethtool
    pciutils 
    usbutils
    nfs-utils

    # apps
    transmission_4-gtk
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.openvpn.servers = {
    officeVPN  = { config = '' config /root/fdn.conf ''; };
  };

  services.transmission = { 
    enable = true; #Enable transmission daemon
    openRPCPort = true; #Open firewall for RPC
    settings = { #Override default settings
      download-dir = "/home/vlp/";
      rpc-bind-address = "0.0.0.0"; #Bind to own IP
      rpc-whitelist = "127.0.0.1,192.168.100.135"; #Whitelist your remote machine (10.0.0.1 in this example)
    };
  };

  systemd={
    tmpfiles.settings = {
      "nas_folders" = {
        "/home/mlc/animations" = {d.mode = "0770";};
      };
    };
  }; 

  fileSystems."/home/mlc/animations" = {
    device = "192.168.100.129:/data/animations";
    fsType = "nfs";
  };

  virtualisation.incus.enable = true;
  networking.nftables.enable = true;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
