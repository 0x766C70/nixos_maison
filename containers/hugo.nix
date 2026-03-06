{
  config,
  pkgs,
  ...
}:
{
  containers.hugo = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.1.42";
    localAddress = "192.168.1.101";
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
          openssh
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
            # Required so azul can maintain a reverse SSH tunnel to expose its port 22
            # on maison's localhost:2222 for the remote backup job.
            AllowTcpForwarding = "yes";
          };
        };

        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [
              80
              433
              1337 # openssh
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
