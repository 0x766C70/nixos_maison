{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./apps.nix
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
      ./services/nfs-mounts.nix
      ./services/luks-disk.nix
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

  # Flakes setup
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  hardware.sane.extraBackends = [ pkgs.epkowa ];

  # Service configurations
  services.openssh = {
    enable = true;
    ports = [ 1337 ];
    settings = {
      PasswordAuthentication = false;
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
  age.secrets.luks_sdb1 = {
    file = ./secrets/luks_sdb1.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # gpg
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Global
  system.stateVersion = "24.11";
}
