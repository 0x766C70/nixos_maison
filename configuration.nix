{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "maison";

  # Enable networking
  networking.networkmanager.enable = true;
  
  # Environment variables
  environment.sessionVariables = rec {
    EDITOR  = "vim";
  };

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
  users.groups.mlc = {};
  users.groups.sftponly = {};
  # User definition
  users.users.vlp = {
    isNormalUser = true;
    description = "vlp";
    extraGroups = [ "networkmanager" "wheel" "incus-admin" "mlc" "transmission" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlXpy4JAK6MQ6JOz/nGRblIYU6CO1PapIgL0SsFRk1C cardno:11_514_955" ];
  };
  users.users.mlc = {
    isNormalUser = true;
    description = "mlc";
    group = "mlc";
    extraGroups = [ "transmission"];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxSyizcTdVqG6+P+/PCq1idtdtDGz8RbiokmjEU0qbI root@LibreELEC" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlXpy4JAK6MQ6JOz/nGRblIYU6CO1PapIgL0SsFRk1C cardno:11_514_955" ];
  };
  users.users.transmission.extraGroups = [ "mlc" ];

  # Enable automatic login for the user.
  services.getty.autologinUser = "vlp";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Flakes setuo
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Package definition
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

    # apps
    transmission_4-gtk
    caddy
  ];

  # Service configurations
  services.openssh = {
    enable = true;
    ports = [ 1337 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "vlp" "mlc" ];
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
    extraConfig = ''
      Subsystem sftp internal-sftp
      Match User mlc
        ChrootDirectory /home/mlc/
        ForceCommand internal-sftp
        X11Forwarding no
        AllowTcpForwarding no
    '';
  };
  services.openvpn.servers = {
    officeVPN  = { config = '' config /root/fdn.conf ''; };
  };

  services.transmission = { 
    enable = true; 
    openRPCPort = true;
    settings = { 
      download-dir = "/home/mlc/downloads/";
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist = "dl.vlp.fdn.fr";
      rpc-whitelist = "*";
    };
  };
  
  services.caddy = {
    enable = true;
    virtualHosts."dl.vlp.fdn.fr".extraConfig = ''
    basic_auth {
      mlc $2a$14$qDVVV0r7JB8QyhswO2/x1utmcYn7XJmMlCE/66hEWdr78.jjmE3Sq
    }
    reverse_proxy http://localhost:9091
    '';
  };
  
  # NAS folder mounting
  systemd={
    tmpfiles.settings = {
      "nas_folders" = {
        "/home/mlc/animations" = {d.mode = "0770";};
      };
      "download_folders" = {
        "/home/mlc/docu" = {d.mode = "0770";};
      };
      "download_folders" = {
        "/home/mlc/ebooks" = {d.mode = "0770";};
      };
      "download_folders" = {
        "/home/mlc/games" = {d.mode = "0770";};
      };
      "download_folders" = {
        "/home/mlc/movies" = {d.mode = "0770";};
      };
      "download_folders" = {
        "/home/mlc/tvshows" = {d.mode = "0770";};
      };
      "download_folders" = {
        "/home/mlc/downloads" = {d.mode = "0770";};
      };
      #"mlc_home_folders" = {
      #  "/home/mlc/" = {d.user = "root"; d.group = "root"; d.mode = "0755";};
      #};
      "nextcloud__folders" = {
        "/home/vlp/nextcloud" = {d.mode = "0700";};
      };
    };
  }; 

  systemd.tmpfiles.rules = [
    "d /home/mlc 0755 root root - -"
  ];

  fileSystems."/home/mlc/animations" = {
    device = "192.168.100.129:/data/animations";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/docu" = {
    device = "192.168.100.129:/data/docu";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/ebooks" = {
    device = "192.168.100.129:/data/ebooks";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/movies" = {
    device = "192.168.100.129:/data/movies";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/tvshows" = {
    device = "192.168.100.129:/data/tvshows";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/downloads" = {
    device = "/dev/mapper/encrypted_drive";
    fsType = "ext4";
  };
  fileSystems."/home/vlp/nextcloud" = {
    device = "192.168.100.129:/data/nextcloud";
    fsType = "nfs";
  };

  # Firewall configuration
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 1337];
  };
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
  
  # Incus configuration
  virtualisation.incus.enable = true;
 
  # Global
  system.stateVersion = "24.11";

}
