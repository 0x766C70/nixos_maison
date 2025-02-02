{ config, pkgs, lib, input, ... }:

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
  users.groups.sftponly = {};
  # User definition
  users.users.vlp = {
    isNormalUser = true;
    description = "vlp";
    extraGroups = [ "networkmanager" "wheel" "incus-admin" "mlc" "transmission" "scanner" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlXpy4JAK6MQ6JOz/nGRblIYU6CO1PapIgL0SsFRk1C cardno:11_514_955" ];
  };
  users.users.mlc = {
    isNormalUser = true;
    description = "mlc";
    group = "mlc";
    extraGroups = [ "transmission" "nextcloud" ];
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
    
    # apps
    transmission_4-gtk
    caddy
  ];
  hardware.sane.extraBackends = [ pkgs.epkowa ];
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
        ChrootDirectory %h
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
      download-dir = "/home/mlc/media/downloads/";
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
    virtualHosts."sandbox.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://localhost:8080
    '';
    virtualHosts."nuage.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://localhost:8080
    '';
  };
  
  # NAS folder mounting
  systemd.tmpfiles.rules = [
    "d /home/mlc/ 0755 root root - -"
    "d /home/mlc/media/ 0750 mlc mlc - -"
    "d /home/mlc/media/animations 0750 mlc mlc - -"
    "d /home/mlc/media/docu 0750 mlc mlc - -"
    "d /home/mlc/media/ebooks 0750 mlc mlc - -"
    "d /home/mlc/media/games 0750 mlc mlc - -"
    "d /home/mlc/media/movies 0750 mlc mlc - -"
    "d /home/mlc/media/tvshows 0750 mlc mlc - -"
    "d /home/mlc/media/downloads 0770 mlc mlc - -"
    "d /home/vlp/backup 0750 vlp vlp - -"
    "d /home/vlp/partages 0750 vlp vlp - -"
  ];

  fileSystems."/home/mlc/media/animations" = {
    device = "192.168.100.129:/data/animations";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/media/docu" = {
    device = "192.168.100.129:/data/docu";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/media/ebooks" = {
    device = "192.168.100.129:/data/ebooks";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/media/games" = {
    device = "192.168.100.129:/data/ebooks";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/media/movies" = {
    device = "192.168.100.129:/data/movies";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/media/tvshows" = {
    device = "192.168.100.129:/data/tvshows";
    fsType = "nfs";
  };
  fileSystems."/home/mlc/media/downloads" = {
    device = "/dev/mapper/encrypted_drive";
    fsType = "ext4";
  };
  fileSystems."/home/vlp/backup" = {
    device = "/dev/mapper/backup_drive";
    fsType = "ext4";
  };
  fileSystems."/home/vlp/partages" = {
    device = "192.168.100.129:/data/partages";
    fsType = "nfs";
  };
  fileSystems."/var/lib/nextcloud/data" = {
    device = "192.168.100.129:/data/nextcloud";
    fsType = "nfs";
  };

  
  # Firewall configuration
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 1337 8080 5432];
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
  };
  age.secrets.mail = {
    file = ./secrets/mail.age;
  };

  # Nextcloud conf
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
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
        trusted_proxies = [ "192.168.100.140" ];
        log_type = "file";
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
      inherit (config.services.nextcloud.package.packages.apps) news contacts calendar tasks;
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

  systemd.services."backup_nc" = {
    script = ''
      ${pkgs.rsync}/bin/rsync -r -t -x --progress --del /var/lib/nextcloud/data/ /home/vlp/backup/nextcloud >> /var/log/timer_nc.log
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
        password = config.age.secrets.prom.path;
      };
    }
    ];
  };

  programs.msmtp = {
  enable = true;
  accounts.default = {
    host = "smtp.fdn.fr";
    from = "maison@vlp.fdn.fr";
    user = "maison@vlp.fdn.fr";
    passwordeval = "$(cat ${config.age.secrets.mail.path})";
  };
};

  # Global
  system.stateVersion = "24.11";
}
