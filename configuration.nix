{ config, pkgs, lib, input, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./services/vim.nix
      ./services/msmtp.nix
      ./services/transmission.nix
      ./services/headscale.nix
      ./services/ttyd.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    hostName = "maison"; 
    networkmanager.enable = true;
    defaultGateway = "192.168.1.1";
    nameservers = [ "1.1.1.1"];
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
  users.groups.mlc = {};
  # User definition
  users.users.vlp = {
    isNormalUser = true;
    description = "vlp";
    extraGroups = [ "networkmanager" "wheel" "incus-admin" "mlc" "scanner" "transmission"];
    packages = with pkgs; [];
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
    transmission_4-gtk
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
      AllowUsers = [ "vlp"];
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  services.openvpn.servers = {
    officeVPN  = { config = '' config /root/fdn.conf ''; };
  };

  services.caddy = {
    enable = true;
    virtualHosts."new-dl.vlp.fdn.fr".extraConfig = ''
      basic_auth {
        mlc $2a$14$qDVVV0r7JB8QyhswO2/x1utmcYn7XJmMlCE/66hEWdr78.jjmE3Sq
      }
      reverse_proxy http://localhost:9091
    '';
    virtualHosts."nuage.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://localhost:8080
    '';
    virtualHosts."laptop.vlp.fdn.fr".extraConfig = ''
      basic_auth / {
		vlp $2a$14$PqyFv42lPq5jJa7gE3jYru2lJ6G5Ne5n4euH68Knnjpcd6Hvs2qE. 
	}	
      reverse_proxy http://192.168.101.13:7681
    '';
    virtualHosts."pihole.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.14:80
    '';
    virtualHosts."web.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.11:80
    '';
    virtualHosts."farfadet.web.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.11:80
    '';
    virtualHosts."cv.web.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.11:80
    '';
    virtualHosts."ai.web.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.11:80
    '';
  };
 
      #basic_auth {
      #  vlp $2a$14$o8owHgahOGlgxZth0xjtLeh5SHpJBuUKIODtP5Pb9HOBtohCLsiRm
      #}

 
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
  };
  fileSystems."/mnt/docu" = {
    device = "192.168.1.10:/data/docu";
    fsType = "nfs";
  };
  fileSystems."/mnt/ebooks" = {
    device = "192.168.1.10:/data/ebooks";
    fsType = "nfs";
  };
  fileSystems."/mnt/games" = {
    device = "192.168.1.10:/data/games";
    fsType = "nfs";
  };
  fileSystems."/mnt/movies" = {
    device = "192.168.1.10:/data/movies";
    fsType = "nfs";
  };
  fileSystems."/mnt/tvshows" = {
    device = "192.168.1.10:/data/tvshows";
    fsType = "nfs";
  };
  fileSystems."/mnt/audio" = {
    device = "192.168.1.10:/data/audio";
    fsType = "nfs";
  };
  #fileSystems."/mnt/downloads" = {
  #  device = "/dev/mapper/encrypted_drive";
  #  fsType = "ext4";
  #};
  #fileSystems."/root/backup" = {
  #  device = "/dev/mapper/backup_drive";
  #  fsType = "ext4";
  #};
  fileSystems."/home/vlp/partages" = {
    device = "192.168.1.10:/data/partages";
    fsType = "nfs";
  };
  fileSystems."/var/lib/nextcloud/data" = {
    device = "192.168.1.10:/data/nextcloud";
    fsType = "nfs";
  };

  
  # Firewall configuration
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 1337 8000 8022 8023 8024 8080 8200 5432];
    allowedUDPPorts = [ 8200 ];
  };
  networking.nat = {
     enable = true;
     internalInterfaces = [ "incusbr1" ];
     externalInterface = "tun0";
     forwardPorts = [
       {
         sourcePort = 8022;
         proto = "tcp";
         destination = "192.168.101.11:22";
       }
       {
         sourcePort = 8023;
         proto = "tcp";
         destination = "192.168.101.12:22";
       }
       {
         sourcePort = 8024;
         proto = "tcp";
         destination = "192.168.101.13:22";
       }
       {
         sourcePort = 8025;
         proto = "tcp";
         destination = "192.168.101.14:22";
       }
       {
         sourcePort = 8026;
         proto = "tcp";
         destination = "192.168.101.15:22";
       }
       {
         sourcePort = 53;
         proto = "udp";
         destination = "192.168.101.14:22";
       }
       {
         sourcePort = 50433;
         proto = "udp";
         destination = "192.168.101.15:50433";
       }
     ];
  };
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
  
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

  # Nextcloud conf
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "localhost";
    database.createLocally = true;
    configureRedis = true;
    maxUploadSize = "1G";
    https = true;
    autoUpdateApps.enable = true;
    config = {
        adminpassFile = config.age.secrets.nextcloud.path;
        dbtype = "pgsql";
    };
    settings = {
        overwriteProtocol = "https";
        default_phone_region = "FR";
        trusted_domains = [ "sandbox.vlp.fdn.fr" "nuage.vlp.fdn.fr"];
        trusted_proxies = [ "192.168.1.42" ];
        log_type = "file";
        memories.exiftool = "${lib.getExe pkgs.exiftool}";
        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\HEIC"
       ];
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) news bookmarks contacts calendar tasks cookbook notes memories previewgenerator deck;
    };
    extraAppsEnable = true;
    phpOptions."opcache.interned_strings_buffer" = "13";
    # extra command
    #nextcloud-occ maintenance:repair --include-expensive
  };
  services.nginx.virtualHosts."localhost".listen = [ { addr = "127.0.0.1"; port = 8080; } ];

  systemd.timers."backup_nc" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar="*-*-* 4:00:00";
        #Persistent = true; 
        Unit = "backup_nc.service";
      };
  };
  systemd.timers."remote_backup_nc" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar="*-*-* 5:00:00";
        #Persistent = true; 
        Unit = "remote_backup_nc.service";
      };
  };

  systemd.services."backup_nc" = {
    script = ''
      ${pkgs.rsync}/bin/rsync -r -t -x --progress --del /var/lib/nextcloud/data/ /root/backup/nextcloud >> /var/log/timer_nc.log
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
  systemd.services."remote_backup_nc" = {
    path = [pkgs.openssh];
    script = ''
      ${pkgs.rsync}/bin/rsync -r -t -x -vv --progress --del /root/backup/nextcloud/ vlp@new-azul.vlp.fdn.fr:/home/vlp/backup_maison/nextcloud/ >> /var/log/timer_nc.log
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers."my_ip" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar="*-*-* 2:00:00";
        Unit = "my_ip.service";
      };
  };

  systemd.services."my_ip" = {
    script = ''
      ${pkgs.curl}/bin/curl https://api.ipify.org\?format\=json 2> /dev/null | ${pkgs.jq}/bin/jq -r '"Subject: ma:son ip\nmaison ip:\(.ip)"' | ${pkgs.msmtp}/bin/msmtp thomas@criscione.fr
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Prometheus

  services.prometheus.exporters.node = {
    enable = true;
    port = 9000;
    enabledCollectors = [ "systemd" ];
    extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi" ];
  };

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s"; # "1m"
    checkConfig = "syntax-only";
    scrapeConfigs = [
    {
      job_name = "nuc_node";
      static_configs = [{
        targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
      }];
    }
    ];
    remoteWrite = [
    {
      url = "https://prometheus-prod-01-eu-west-0.grafana.net/api/prom/push";
      basic_auth = {
        username =  "737153";
        password_file = config.age.secrets.prom.path;
      };
    }
    ];
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
 
  #DLNA
  services.avahi.enable = true;
  services.minidlna.enable = true;
  services.minidlna.openFirewall = true;
  services.minidlna.settings = {
    friendly_name = "NAS";
    media_dir = [
      "V,/mnt/animations/"
      "V,/mnt/audio/"
      "V,/mnt/docu/"
    ];
    log_level = "warn";
    inotify = "yes";
    #announceInterval = 05;
  };

  users.users.minidlna = {
  extraGroups = [ "users" ]; # so minidlna can access the files.
  };
 
  # Global
  system.stateVersion = "24.11";
}
