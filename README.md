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
- **Mesh VPN**: Headscale for secure device-to-device connectivity
- **Intrusion Prevention**: fail2ban protecting SSH, web services, and Nextcloud from brute-force attacks

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

- Nextcloud: `https://nuage.vlp.fdn.fr`
- Transmission: `https://dl.vlp.fdn.fr`
- Terminal: `https://ttyd.vlp.fdn.fr`
- Headscale: `https://hs.vlp.fdn.fr` (see [HEADSCALE.md](HEADSCALE.md) for setup)

## 🔐 Secrets Management

Secrets are managed using [agenix](https://github.com/ryantm/agenix):

```bash
# Edit secrets (requires age key)
agenix -e secrets/mySecret.age
```

Secrets are defined in `secrets/secrets.nix` and configured in `configuration.nix`.

## 🔧 Maintenance

### Security & Intrusion Prevention

The server is protected by **fail2ban**, which automatically bans IPs after repeated failed authentication attempts.

#### fail2ban Management

Use the included management script for easy monitoring:

```bash
# Check fail2ban status and active jails
sudo scripts/fail2ban-manager.sh status

# View all currently banned IPs
sudo scripts/fail2ban-manager.sh banned

# Show detailed jail statistics
sudo scripts/fail2ban-manager.sh jails

# View recent ban activity
sudo scripts/fail2ban-manager.sh activity

# Unban an IP address (if you locked yourself out!)
sudo scripts/fail2ban-manager.sh unban 203.0.113.42

# Manually ban an IP in a specific jail
sudo scripts/fail2ban-manager.sh ban sshd 203.0.113.99

# View fail2ban logs
sudo scripts/fail2ban-manager.sh logs 100

# Monitor banned IPs in real-time
watch -n 5 sudo scripts/fail2ban-manager.sh banned
```

#### Protected Services

- **SSH** (port 1337): 3 failed attempts → 2-hour ban
- **Caddy Basic Auth** (dl.vlp.fdn.fr, laptop.vlp.fdn.fr): 5 attempts → 1-hour ban
- **Nextcloud**: 3 failed logins → 1-hour ban
- **HTTP Auth**: 5 failed attempts → 1-hour ban

All bans trigger email notifications to `monitoring@vlp.fdn.fr`.

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
