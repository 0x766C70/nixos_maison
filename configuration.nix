{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./services/firewall.nix
      ./services/vim.nix
      ./services/msmtp.nix
      ./services/dlna.nix
      ./services/transmission.nix
      ./services/caddy.nix
      ./services/headscale.nix
      ./services/ttyd.nix
      ./services/nextcloud.nix
      ./services/prom.nix
      ./services/timers.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    hostName = "maison";
    networkmanager.enable = true;
    defaultGateway = "192.168.1.1";
    nameservers = [ "1.1.1.1" ];
    interfaces = {
      eno1.ipv4.addresses = [{
        address = "192.168.1.42";
        prefixLength = 24;
      }];
    };
  };

  hardware.sane.enable = true;

  # Local settings.
  time.timeZone = "Europe/Paris";
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
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };
  console.keyMap = "us-acentos";

  # Group definitions
  users.groups.mlc = { };
  # User definition
  users.users.vlp = {
    isNormalUser = true;
    description = "vlp";
    extraGroups = [ "networkmanager" "wheel" "incus-admin" "mlc" "scanner" "transmission" ];
    packages = with pkgs; [ ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlXpy4JAK6MQ6JOz/nGRblIYU6CO1PapIgL0SsFRk1C cardno:11_514_955" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZkKbJKyVDNdbwNiVC9mb87ACxWJrm5ZxLjysdiLVEo vlp@vlaptop" ];
  };
  users.users.transmission.extraGroups = [ "mlc" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Flakes setuo
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Package definition
  environment.systemPackages = with pkgs; [

    # basic tools
    vim
    neovim
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
    lynx
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
    pass

    # productivity
    glow

    # monitoring
    btop
    iotop
    iftop

    # system call monitoring
    strace
    ltrace
    lsof

    # system tools
    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
    nfs-utils
    go
    epsonscan2
    ncdu
    speedtest-go

    # NC dependencies
    exiftool
    ffmpeg
    imagemagick
    nodejs
    perl

    # apps
    caddy
    ttyd
    minidlna
    inotify-tools
  ];
  hardware.sane.extraBackends = [ pkgs.epkowa ];

  # Service configurations
  services.openssh = {
    enable = true;
    ports = [ 1337 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "vlp" ];
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Openvpn static conf
  services.openvpn.servers = {
    officeVPN = { config = '' config /root/fdn.conf ''; };
  };

  # NAS folder mounting
  systemd.tmpfiles.rules = [
    "d /mnt/animations 0751 vlp vlp - -"
    "d /mnt/audio 0751 vlp vlp - -"
    "d /mnt/docu 0755 vlp vlp - -"
    "d /mnt/ebooks 0755 vlp vlp - -"
    "d /mnt/games 0755 vlp vlp - -"
    "d /mnt/movies 0755 vlp vlp - -"
    "d /mnt/tvshows 0755 vlp vlp - -"
    "d /mnt/downloads 0775 vlp vlp - -"
    "d /root/backup 0750 root root - -"
    "d /home/vlp/partages 0750 vlp vlp - -"
  ];

  fileSystems."/mnt/animations" = {
    device = "192.168.1.10:/data/animations";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/docu" = {
    device = "192.168.1.10:/data/docu";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/ebooks" = {
    device = "192.168.1.10:/data/ebooks";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/games" = {
    device = "192.168.1.10:/data/games";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/movies" = {
    device = "192.168.1.10:/data/movies";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/tvshows" = {
    device = "192.168.1.10:/data/tvshows";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/audio" = {
    device = "192.168.1.10:/data/audio";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/home/vlp/partages" = {
    device = "192.168.1.10:/data/partages";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/var/lib/nextcloud/data" = {
    device = "192.168.1.10:/data/nextcloud";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };


  # Incus configuration
  virtualisation.incus.enable = true;

  # agix configuration
  age.identityPaths = [ "/root/.ssh/id_ed25519" ];
  age.secrets.nextcloud = {
    file = ./secrets/nextcloud.age;
    owner = "nextcloud";
    group = "nextcloud";
  };
  age.secrets.prom = {
    file = ./secrets/prom.age;
    owner = "prometheus";
    group = "prometheus";
  };
  age.secrets.caddy_mlc = {
    file = ./secrets/caddy_mlc.age;
    owner = "caddy";
    group = "caddy";
  };
  age.secrets.caddy_vlp = {
    file = ./secrets/caddy_vlp.age;
    owner = "caddy";
    group = "caddy";
  };
  age.secrets.mail = {
    file = ./secrets/mail.age;
  };

  # gpg
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Global
  system.stateVersion = "24.11";
}
