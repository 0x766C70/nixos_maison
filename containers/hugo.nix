{
  config,
  pkgs,
  ...
}:
{
  containers.hugo = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "10.0.0.1";   # host-side veth — must not conflict with eno1 (192.168.1.42)
    localAddress = "10.0.0.2";  # container-side veth
    config =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        environment.systemPackages = with pkgs; [

          # basic tools
          vim
          git
          hugo
        ];

        users.users.vlp = {
          isNormalUser = true;
          description = "vlp";
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
          packages = with pkgs; [ ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlXpy4JAK6MQ6JOz/nGRblIYU6CO1PapIgL0SsFRk1C cardno:11_514_955"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZkKbJKyVDNdbwNiVC9mb87ACxWJrm5ZxLjysdiLVEo vlp@vlaptop"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJjhXY6k35R5uEcI1agihEFjee9vjE69v8dpxa4o8Y9b vlp@azul"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8tl4ACfbuY+gY33fBKAu/V9UbXZVXIYSdHDNRLOjQv (none)"
          ];
        };

        services.openssh = {
          enable = true;
          ports = [ 1337 ];
          settings = {
            PasswordAuthentication = false;
            AllowUsers = [ "vlp" ];
            UseDns = true;
            X11Forwarding = false;
            PermitRootLogin = "prohibit-password";
            AllowTcpForwarding = "yes";
          };
        };

        networking = {
          defaultGateway = "10.0.0.1"; # host-side veth — gateway for NAT through eno1
          nameservers = [ "1.1.1.1" ];
          firewall = {
            enable = true;
            allowedTCPPorts = [
              80
              443
              1337
            ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        services.resolved.enable = true;

        system.stateVersion = "24.11";
      };
  };
}
