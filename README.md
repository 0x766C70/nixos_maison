# NixOS Maison 🏠

A declarative NixOS configuration for a home server providing cloud storage, media streaming, torrent management, and automated backups.

## ✨ Features

- **Cloud Storage**: Nextcloud 32 with PostgreSQL backend and Redis caching
- **Reverse Proxy**: Caddy server managing multiple virtual hosts with HTTPS
- **Media Server**: MiniDLNA streaming to local network devices
- **Torrent Client**: Transmission with Flood web interface
- **Monitoring**: Prometheus with node exporter and Grafana Cloud integration
- **Security**: fail2ban intrusion prevention for SSH, Caddy basic auth, and Nextcloud brute force protection
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
│   ├── fail2ban.nix          # Intrusion prevention
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
# Test configuration (dry-activate — preview changes without applying)
frd

# Build and switch
fr
```

### Access Services

The server runs on static IP `192.168.1.42` with the following services:

- Nextcloud: `https://nuage.vlp.fdn.fr`
- Transmission: `https://dl.vlp.fdn.fr`

## 🔐 Secrets Management

Secrets are managed using [agenix](https://github.com/ryantm/agenix):

```bash
# Edit secrets (requires age key) echo tricks or it add a LR at the end
echo -n "super p4ssw0rd" | agenix -e secrets/mySecret.age
```

Secrets are defined in `secrets/secrets.nix` and configured in `configuration.nix`.

## 🔧 Maintenance

### Backups

Automated backups run via systemd timers:
- **Nextcloud backup**: Daily at 4:00 AM → `/root/backup/nextcloud/`
- **Remote backup**: Daily at 5:00 AM → `azul.vlp.fdn.fr:/home/vlp/backup_maison/nextcloud/`

### Monitoring

System metrics are collected by Prometheus and forwarded to Grafana Cloud for visualization: h766c70.grafana.net

Timer alerts are sent from monitoring@766c70.com to contact@766c70.com

### Security (fail2ban)

fail2ban protects SSH (port 1337), Caddy basic auth, and Nextcloud from brute force attacks:

**SSH Protection:**
- **Ban threshold**: 5 failed attempts within 10 minutes
- **Ban duration**: 1 hour
- **Backend**: systemd journal (NixOS native)

**Nextcloud Login Protection:**
- **Ban threshold**: 5 failed login attempts within 10 minutes
- **Ban duration**: 2 hours
- **Protected service**: `nuage.vlp.fdn.fr` (Nextcloud instance)
- **Log format**: JSON logs in `/var/lib/nextcloud/data/nextcloud.log`
- **Detection**: Failed logins and trusted domain errors

```bash
# Check fail2ban status
sudo systemctl status fail2ban

# View banned IPs for SSH
sudo fail2ban-client status sshd

# View banned IPs for Nextcloud
sudo fail2ban-client status nextcloud

# Manually ban an IP (for SSH)
sudo fail2ban-client set sshd banip <IP_ADDRESS>

# Manually ban an IP (for Nextcloud)
sudo fail2ban-client set nextcloud banip <IP_ADDRESS>

# Manually unban an IP (for SSH)
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>

# Manually unban an IP (for Nextcloud)
sudo fail2ban-client set nextcloud unbanip <IP_ADDRESS>

# View recent login failures in Nextcloud logs
sudo grep '"Login failed:' /var/lib/nextcloud/data/nextcloud.log | tail -n 50
```

### Transmission — Pruning old finished torrents

The script `bin/transmission-prune-finished-30d.sh` removes finished torrents
that were added more than 30 days ago and deletes their local data.

```bash
# Dry run (preview only, no deletions)
DRY_RUN=1 ./bin/transmission-prune-finished-30d.sh

# Actually prune torrents older than 30 days
./bin/transmission-prune-finished-30d.sh

# Custom threshold (e.g. 60 days) or non-default host/port
THRESHOLD_DAYS=60 TR_HOST=192.168.1.42 TR_PORT=9091 ./bin/transmission-prune-finished-30d.sh

# With authentication
TR_AUTH=user:pass ./bin/transmission-prune-finished-30d.sh
```

Environment variables:

| Variable         | Default       | Description                                      |
|------------------|---------------|--------------------------------------------------|
| `TR_HOST`        | `127.0.0.1`   | Transmission RPC host                            |
| `TR_PORT`        | `9091`        | Transmission RPC port                            |
| `THRESHOLD_DAYS` | `30`          | Minimum age in days before a torrent is pruned   |
| `DRY_RUN`        | `0`           | Set to `1` to preview deletions without running  |
| `TR_AUTH`        | *(unset)*     | `user:pass` passed to `--auth` if set            |

### Updates

```bash
# Update flake inputs
nix flake update

# Apply updates
fr
```

## 🛠️ Customization

1. **Network Settings**: Edit static IP in `configuration.nix`
2. **Services**: Enable/disable services in `configuration.nix` imports
3. **Packages**: Add system packages to `apps.nix`
4. **User Environment**: Modify shell and tools in `home.nix`

## 📝 License

This is a personal configuration. Feel free to use it as inspiration for your own NixOS setup.
