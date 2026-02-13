# NixOS Maison 🏠

A declarative NixOS configuration for a home server providing cloud storage, media streaming, torrent management, and automated backups.

## ✨ Features

- **Cloud Storage**: Nextcloud 31 with PostgreSQL backend and Redis caching
- **Reverse Proxy**: Caddy server managing multiple virtual hosts with HTTPS
- **Media Server**: MiniDLNA streaming to local network devices
- **Torrent Client**: Transmission with Flood web interface
- **Monitoring**: Prometheus with node exporter and Grafana Cloud integration
- **Automated Backups**: Scheduled Nextcloud and system backups to remote server
- **Encrypted Storage**: LUKS-encrypted backup disk with automatic unlock
- **Network Services**: NFS mounts, OpenVPN, SSH, and firewall management
- **Secrets Management**: Agenix for encrypted configuration secrets

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
│   ├── transmission.nix      # Torrent client
│   ├── dlna.nix              # Media streaming
│   ├── prom.nix              # Monitoring
│   ├── firewall.nix          # nftables + NAT
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

- Nextcloud: `https://nuage.vlp.fdn.fr`
- Downloads: `https://dl.vlp.fdn.fr`
- Transmission: `http://192.168.1.42:9091`
- Terminal: `https://ttyd.vlp.fdn.fr`

## 🔐 Secrets Management

Secrets are managed using [agenix](https://github.com/ryantm/agenix):

```bash
# Edit secrets (requires age key)
agenix -e secrets/nextcloud.age
```

Secrets are defined in `secrets/secrets.nix` and configured in `configuration.nix`.

## 🔧 Maintenance

### Backups

Automated backups run via systemd timers:
- **Nextcloud backup**: Daily at 4:00 AM → `/root/backup/nextcloud/`
- **Remote backup**: Daily at 5:00 AM → `ovh1.vinci.ovh:/backup/vlp/`

### Monitoring

System metrics are collected by Prometheus and forwarded to Grafana Cloud for visualization.

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
