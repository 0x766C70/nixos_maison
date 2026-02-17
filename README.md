# NixOS Maison 🏠

A declarative NixOS configuration for a home server providing cloud storage, media streaming, torrent management, and automated backups.

## ✨ Features

- **Cloud Storage**: Nextcloud 32 with PostgreSQL backend and Redis caching
- **Media Server**: Jellyfin (modern Netflix-like UI) + MiniDLNA for DLNA devices
- **Document Management**: Paperless-ngx with OCR for digitizing family documents
- **Reverse Proxy**: Caddy server managing multiple virtual hosts with HTTPS
- **Torrent Client**: Transmission with Flood web interface
- **Family Portal**: Homepage dashboard with links to all services
- **Network Security**: AdGuard Home (DNS-based ad blocking + parental controls)
- **Intrusion Prevention**: fail2ban protecting SSH and web services
- **Monitoring**: Prometheus + Grafana Cloud + Uptime Kuma for service monitoring
- **Automated Backups**: Scheduled Nextcloud and system backups to remote server
- **Auto Updates**: Weekly security updates with email notifications
- **Encrypted Storage**: LUKS-encrypted backup disk with automatic unlock
- **Disk Health**: S.M.A.R.T. monitoring with failure alerts
- **Network Services**: NFS mounts, OpenVPN, SSH, and firewall management
- **Secrets Management**: Agenix for encrypted configuration secrets
- **Mesh VPN**: Headscale for secure device-to-device connectivity

## 📁 Structure

```
├── flake.nix                  # Nix flakes configuration
├── configuration.nix          # Main NixOS system configuration
├── hardware-configuration.nix # Hardware-specific settings
├── home.nix                   # Home Manager user environment
├── apps.nix                   # System packages
├── services/                  # Modular service configurations
│   ├── caddy.nix             # Reverse proxy
│   ├── nextcloud.nix         # Cloud storage
│   ├── jellyfin.nix          # Media server
│   ├── transmission.nix      # Torrent client
│   ├── dlna.nix              # DLNA media streaming
│   ├── paperless.nix         # Document management
│   ├── homepage.nix          # Dashboard
│   ├── adguard.nix           # DNS ad blocker
│   ├── fail2ban.nix          # Intrusion prevention
│   ├── uptime-kuma.nix       # Service monitoring
│   ├── smartd.nix            # Disk health monitoring
│   ├── auto-upgrade.nix      # Automatic updates
│   ├── prom.nix              # Prometheus metrics
│   ├── firewall.nix          # nftables + NAT
│   ├── headscale.nix         # Mesh VPN
│   ├── timers.nix            # Backup automation
│   └── ...
└── secrets/                   # Age-encrypted secrets

```

## 🚀 Quick Start

### Prerequisites

- NixOS with flakes enabled
- Age keys configured for secrets decryption

### Build and Deploy

```bash
# Test configuration
nixos-rebuild dry-build --flake .#maison

# Build and switch
sudo nixos-rebuild switch --flake .#maison
```

### Access Services

The server runs on static IP `192.168.1.42` with the following services:

- **Family Portal**: `https://home.vlp.fdn.fr` - Dashboard with all service links
- **Nextcloud**: `https://nuage.vlp.fdn.fr` - Cloud storage
- **Jellyfin**: `https://media.vlp.fdn.fr` or `http://192.168.1.42:8096` - Media streaming
- **Transmission**: `https://dl.vlp.fdn.fr` - Torrent downloads
- **Paperless**: `https://docs.vlp.fdn.fr` - Document management
- **AdGuard Home**: `http://192.168.1.42:3000` - DNS & ad blocker (local only)
- **Uptime Kuma**: `https://status.vlp.fdn.fr` - Service monitoring
- **Headscale**: `https://hs.vlp.fdn.fr` - VPN control panel (see [HEADSCALE.md](HEADSCALE.md))

📖 **See [NEW_FEATURES.md](NEW_FEATURES.md) for detailed setup guides for all services!**

## 🔐 Secrets Management

Secrets are managed using [agenix](https://github.com/ryantm/agenix):

```bash
# Edit secrets (requires age key)
agenix -e secrets/mySecret.age
```

Secrets are defined in `secrets/secrets.nix` and configured in `configuration.nix`.

## 🔧 Maintenance

### Backups

Automated backups run via systemd timers:
- **Nextcloud backup**: Daily at 4:00 AM → `/root/backup/nextcloud/`
- **Remote backup**: Daily at 5:00 AM → `azul.vlp.fdn.fr:/home/vlp/backup_maison/nextcloud/`

### Monitoring

System metrics are collected by Prometheus and forwarded to Grafana Cloud for visualization: vlpfdnfr.grafana.net

### Updates

```bash
# Update flake inputs
nix flake update

# Apply updates
sudo nixos-rebuild switch --flake .#maison
```

## 🛠️ Customization

1. **Network Settings**: Edit static IP in `configuration.nix`
2. **Services**: Enable/disable services in `configuration.nix` imports
3. **Packages**: Add system packages to `apps.nix`
4. **User Environment**: Modify shell and tools in `home.nix`

## 📝 License

This is a personal configuration. Feel free to use it as inspiration for your own NixOS setup.
