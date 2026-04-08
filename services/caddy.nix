{ config
, lib
, pkgs
, ...
}:
let
  alicantePath = "/var/www/alicante/public";
in
{
  # ---------------------------------------------------------------------------
  # Eval-time sanity check — caught before nixos-rebuild even touches the disk.
  # ---------------------------------------------------------------------------
  assertions = [
    {
      # Catches accidental relative paths (e.g. "var/www/alicante") that Caddy
      # would silently resolve from its working directory instead of filesystem root.
      assertion = lib.hasPrefix "/" alicantePath;
      message = "caddy: alicantePath (\"${alicantePath}\") must be an absolute path.";
    }
  ];

  services.caddy = {
    enable = true;

    # No global logging - each virtualhost with auth has its own log file for fail2ban

    virtualHosts."nuage.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://localhost:8080 {
        # Pass real client IP to Nextcloud
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
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
    virtualHosts."alicante.vlp.fdn.fr".extraConfig = ''
      
      root * ${alicantePath}
      file_server
      encode zstd gzip

      # Basic security headers for a static site
      header {
        # Prevent MIME-type sniffing attacks
        X-Content-Type-Options "nosniff"
        # Disallow embedding in iframes from other origins
        X-Frame-Options "SAMEORIGIN"
        # Limit referrer leakage
        Referrer-Policy "strict-origin-when-cross-origin"
        # Cache static assets for 1 hour; clients revalidate after that
        Cache-Control "public, max-age=3600, must-revalidate"
      }
    '';
  };

  # ---------------------------------------------------------------------------
  # Directory provisioning
  # ---------------------------------------------------------------------------
  # Ensure all required directories exist with the correct ownership/permissions.
  # 'd' creates the directory if absent but does NOT alter an existing one.
  systemd.tmpfiles.rules = [
    # Caddy log directory (used by per-vhost access logs and fail2ban)
    "d /var/log/caddy 0770 caddy caddy -"
    "d /var/www 0755 caddy caddy -"
    "d ${alicantePath} 0770 caddy caddy -"
  ];
  # No homeMode or extraGroups hacks needed — /var/www lives outside any home
  # directory, so Caddy reaches it without any special filesystem gymnastics.
}
