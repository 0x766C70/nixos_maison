{ config
, pkgs
, ...
}:
{
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    webHome = pkgs.flood-for-transmission;
    settings = {
      incomplete-dir = "/mnt/downloads/.incomplete/";
      download-dir = "/mnt/downloads/";
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist = "maison.vlpnet.hs.766c70.com";
      rpc-whitelist = "127.0.0.1,100.64.0.4,100.64.0.7,100.64.0.1";

      # --- Peer connectivity ---
      # Fixed port so the firewall rule always matches after restarts
      peer-port = 51413;
      peer-port-random-on-start = false;

      # µTP runs over UDP — critical for upload throughput and NAT traversal
      utp-enabled = true;

      # Peer discovery mechanisms
      dht-enabled = true; # Distributed Hash Table — finds peers without a tracker
      pex-enabled = true; # Peer Exchange — peers share their peer lists with you
      lpd-enabled = true; # Local Peer Discovery — useful on LAN

      # --- Peer limits ---
      # Defaults (200 global / 50 per torrent) are too conservative for popular torrents
      peer-limit-global = 400;
      peer-limit-per-torrent = 100;

      # --- Upload tuning ---
      # More upload slots = more concurrent upload streams per torrent
      upload-slots-per-torrent = 14;

      # Ensure no artificial upload speed cap is applied
      speed-limit-up-enabled = false;

      # --- Seeding policy ---
      # Do not stop seeding based on a ratio threshold
      ratio-limit-enabled = false;

      # Do not cap the number of torrents being seeded simultaneously
      seed-queue-enabled = false;
    };
  };
}
