# NixOS Maison 🏠

A declarative NixOS configuration for a home server providing cloud storage, media streaming, torrent management, and automated backups.

## ✨ Features

- **Cloud Storage**: Nextcloud 31 with PostgreSQL backend and Redis caching
- **Reverse Proxy**: Caddy server managing multiple virtual hosts with HTTPS
- **Media Server**: MiniDLNA streaming to local network devices
- **Torrent Client**: Transmission with Flood web interface
- **Monitoring**: Prometheus with node exporter and Grafana Cloud integration
- **Security**: fail2ban intrusion prevention for SSH and Caddy basic auth brute force protection
- **Automated Backups**: Scheduled Nextcloud and system backups to remote server
- **Encrypted Storage**: LUKS-encrypted backup disk with automatic unlock
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

### Backups

Automated backups run via systemd timers:
- **Nextcloud backup**: Daily at 4:00 AM → `/root/backup/nextcloud/`
- **Remote backup**: Daily at 5:00 AM → `azul.vlp.fdn.fr:/home/vlp/backup_maison/nextcloud/`

### Monitoring

System metrics are collected by Prometheus and forwarded to Grafana Cloud for visualization: vlpfdnfr.grafana.net

### Security (fail2ban)

fail2ban protects SSH (port 1337) and Caddy basic auth from brute force attacks:

**SSH Protection:**
- **Ban threshold**: 5 failed attempts within 10 minutes
- **Ban duration**: 1 hour
- **Backend**: systemd journal (NixOS native)

**Caddy Basic Auth Protection:**
- **Ban threshold**: 3 failed attempts within 10 minutes
- **Ban duration**: 2 hours
- **Protected endpoints**: 
  - `dl.vlp.fdn.fr` (Transmission web interface)
  - `laptop.vlp.fdn.fr` (Laptop remote access)
- **Log format**: JSON logs in `/var/log/caddy/access.log`

```bash
# Check fail2ban status
sudo systemctl status fail2ban

# View banned IPs for SSH
sudo fail2ban-client status sshd

# View banned IPs for Caddy
sudo fail2ban-client status caddy-auth

# Manually ban an IP (for SSH)
sudo fail2ban-client set sshd banip <IP_ADDRESS>

# Manually ban an IP (for Caddy)
sudo fail2ban-client set caddy-auth banip <IP_ADDRESS>

# Manually unban an IP (for SSH)
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>

# Manually unban an IP (for Caddy)
sudo fail2ban-client set caddy-auth unbanip <IP_ADDRESS>

# View recent authentication failures in Caddy logs
sudo journalctl -u caddy -n 50 | grep 401
```

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
