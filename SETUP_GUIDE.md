# 🚀 Quick Start Guide - Setting Up Your Enhanced Homeserver

This guide will help you deploy and configure all the new services.

## ⚡ Quick Deploy

### 1. Review Changes

```bash
cd /home/vlp/nixos_maison
git pull origin main  # or your branch
git diff HEAD~1       # Review what changed
```

### 2. Test Build (Dry Run)

```bash
sudo nixos-rebuild dry-build --flake .#maison
```

This checks for syntax errors without making changes.

### 3. Deploy Changes

```bash
sudo nixos-rebuild switch --flake .#maison
```

**Note:** First build will take 10-20 minutes as it downloads and compiles all new services.

### 4. Verify Services Started

```bash
./scripts/homeserver-manage.sh status
```

Or check individual services:
```bash
systemctl status jellyfin
systemctl status adguardhome
systemctl status fail2ban
systemctl status homepage-dashboard
```

---

## 🎯 Initial Configuration (Required)

After deployment, configure these services:

### 1. AdGuard Home (CRITICAL)

**Why first:** Network-wide ad blocking and parental controls.

```bash
# Access at http://192.168.1.42:3000
# Follow setup wizard:
# 1. Create admin account
# 2. Note the username/password
# 3. Configure router to use 192.168.1.42 as DNS
```

**Router configuration:**
- Login to your router (usually 192.168.1.1)
- Find DHCP settings
- Set primary DNS to: `192.168.1.42`
- Set secondary DNS to: `1.1.1.1` (fallback)
- Save and reboot router

**Important:** All devices will now use AdGuard for DNS. Test by visiting a known ad-heavy site.

### 2. Jellyfin Media Server

```bash
# Access at http://192.168.1.42:8096
# Follow setup wizard:
```

1. **Create admin account** - Choose strong password
2. **Add media libraries:**
   - Movies: `/mnt/movies`
   - TV Shows: `/mnt/tvshows`
   - Music: `/mnt/audio`
   - Animations: `/mnt/animations`
   - Documentaries: `/mnt/docu`
3. **Configure metadata:**
   - Enable automatic metadata download
   - Choose your preferred metadata provider (TheMovieDB, TVDb)
4. **Setup users:**
   - Create accounts for each family member
   - Configure parental controls if needed
5. **Install apps:**
   - Download Jellyfin apps for phones, tablets, smart TVs
   - Login with your credentials

### 3. Uptime Kuma (Service Monitoring)

```bash
# Access at https://status.vlp.fdn.fr
```

1. Create admin account
2. Add monitors for each service:
   - **Nextcloud**: HTTP check for `https://nuage.vlp.fdn.fr`
   - **Jellyfin**: HTTP check for `http://192.168.1.42:8096`
   - **Caddy**: HTTP check for `https://home.vlp.fdn.fr`
   - **SSH**: Port check for `192.168.1.42:1337`
   - **AdGuard**: HTTP check for `http://192.168.1.42:3000`
3. Configure notifications (email, Telegram, etc.)
4. Set check intervals (60 seconds recommended)

### 4. Homepage Dashboard

```bash
# Access at https://home.vlp.fdn.fr
```

No configuration needed! It's pre-configured with all services.

**Customize:**
Edit `/home/vlp/nixos_maison/services/homepage.nix` to add more services or widgets.

### 5. Paperless-ngx (Document Management)

```bash
# Access at https://docs.vlp.fdn.fr
```

1. Create admin account
2. Configure scanner/upload:
   - Web upload works immediately
   - For scanner: Configure to save to NFS share mounted at server
3. Add tags and correspondents
4. Test OCR with a sample document

---

## 🔐 Security Hardening (Do These Next)

### 1. Check fail2ban is Working

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

**Test it (optional):**
```bash
# From another machine, try failed SSH login:
ssh nonexistentuser@192.168.1.42 -p 1337
# (try 3 times with wrong password)

# Check if IP was banned:
sudo fail2ban-client status sshd
```

### 2. Configure smartd Email Alerts

Test that disk monitoring emails work:
```bash
# This should send a test email to monitoring@vlp.fdn.fr
sudo systemctl restart smartd
journalctl -u smartd -n 20
```

Check your email to confirm you received the test notification.

### 3. Verify Auto-Upgrade is Scheduled

```bash
systemctl list-timers nixos-upgrade
```

Should show next run time (Sundays at 3 AM).

### 4. Test Backup Notifications

Manually trigger a backup to verify email notifications work:
```bash
sudo systemctl start backup_nc.service
journalctl -u backup_nc -f
```

---

## 📱 Optional Services Setup

Enable these services as needed. See `NEW_FEATURES.md` for details.

### Enable Vaultwarden (Password Manager)

1. Edit `configuration.nix`:
   ```nix
   # Uncomment this line:
   ./services/vaultwarden.nix
   ```

2. Edit `services/caddy.nix`:
   ```nix
   # Uncomment the vault.vlp.fdn.fr virtualHost
   ```

3. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake .#maison
   ```

4. Access https://vault.vlp.fdn.fr and create admin account

### Enable Grafana (Local Monitoring)

Same process as Vaultwarden:
1. Uncomment in `configuration.nix`
2. Uncomment in `services/caddy.nix`
3. Rebuild
4. Access https://grafana.vlp.fdn.fr

Default credentials: `admin` / `admin` (change immediately!)

---

## 🧪 Testing Your Setup

### Service Availability Test

```bash
# Use the management script
./scripts/homeserver-manage.sh status
```

Or manually check each service:

```bash
# Test Jellyfin
curl -I http://192.168.1.42:8096

# Test Homepage
curl -I https://home.vlp.fdn.fr

# Test Nextcloud
curl -I https://nuage.vlp.fdn.fr

# Test AdGuard DNS
dig google.com @192.168.1.42
```

### Backup Test

```bash
# Check backup mount point
mountpoint /root/backup

# Test Nextcloud backup
sudo systemctl start backup_nc.service
sudo journalctl -u backup_nc -n 50

# Verify backup exists
ls -lh /root/backup/nextcloud/
```

### Network Test

```bash
# Test DNS blocking (should be blocked if AdGuard is configured)
dig ads.google.com @192.168.1.42

# Test from client device after router DNS change
nslookup doubleclick.net
```

---

## 📊 Monitoring Your Server

### Use the Management Script

```bash
./scripts/homeserver-manage.sh

# Or use direct commands:
./scripts/homeserver-manage.sh status      # Service status
./scripts/homeserver-manage.sh resources   # CPU, RAM, disk
./scripts/homeserver-manage.sh backup      # Backup status
./scripts/homeserver-manage.sh disks       # Disk health
./scripts/homeserver-manage.sh fail2ban    # Security bans
./scripts/homeserver-manage.sh urls        # Service URLs
```

### Important Monitoring Points

1. **Email alerts** at `monitoring@vlp.fdn.fr`:
   - Backup failures
   - Disk health issues
   - Auto-upgrade status

2. **Uptime Kuma** at `https://status.vlp.fdn.fr`:
   - Service availability
   - Response times
   - Uptime statistics

3. **Grafana** (if enabled) at `https://grafana.vlp.fdn.fr`:
   - CPU, memory, disk usage
   - Network traffic
   - Service-specific metrics

4. **AdGuard Home** at `http://192.168.1.42:3000`:
   - DNS query logs
   - Blocked requests
   - Top clients and domains

---

## 🔄 Regular Maintenance

### Weekly Tasks

```bash
# Check service status
./scripts/homeserver-manage.sh status

# Review fail2ban bans
sudo fail2ban-client status

# Check disk space
df -h
```

### Monthly Tasks

```bash
# Check disk health
sudo smartctl -a /dev/sda

# Review backup status
./scripts/homeserver-manage.sh backup

# Test backup restore (important!)
# Restore a test file from backup to verify integrity

# Update system if auto-upgrade is disabled
sudo nixos-rebuild switch --flake .#maison
```

### Quarterly Tasks

- Review Uptime Kuma statistics
- Audit user accounts on all services
- Check Jellyfin storage usage
- Review AdGuard Home blocked domains
- Test emergency restore procedures

---

## 🆘 Troubleshooting

### Service Won't Start

```bash
# Check service status and logs
systemctl status service-name
journalctl -u service-name -n 100 --no-pager

# Common issues:
# 1. Port already in use
# 2. Permission issues
# 3. Configuration syntax error
# 4. Missing dependencies
```

### Can't Access Service Web Interface

```bash
# Check service is running
systemctl status service-name

# Check if port is listening
ss -tlnp | grep PORT

# Check Caddy is proxying
systemctl status caddy
journalctl -u caddy -n 50

# Check firewall
sudo nft list ruleset | grep PORT
```

### Backup Failed

```bash
# Check email alert details
# Check backup mount
mountpoint /root/backup

# Check LUKS disk service
systemctl status luks-sdb1-unlock.service

# Manual backup test
sudo rsync -av --dry-run \
  /var/lib/nextcloud/data/ \
  /root/backup/nextcloud/
```

### AdGuard Not Blocking Ads

```bash
# Check AdGuard is running
systemctl status adguardhome

# Test DNS resolution
dig ads.google.com @192.168.1.42

# Verify device is using correct DNS
# On client device:
nslookup google.com
# Should show 192.168.1.42 as server

# Check AdGuard query log via web UI
```

### High CPU/Memory Usage

```bash
# Check top processes
htop

# Likely culprits:
# - Jellyfin transcoding (normal during playback)
# - PhotoPrism indexing (normal on first run)
# - Nextcloud preview generation

# Check specific service logs
journalctl -u jellyfin -f
```

---

## 📝 Post-Setup Checklist

- [ ] All core services are running
- [ ] AdGuard Home is configured and router DNS is updated
- [ ] Jellyfin media libraries are added and scanning
- [ ] Uptime Kuma monitors are configured with notifications
- [ ] Paperless admin account is created
- [ ] Homepage dashboard is accessible
- [ ] fail2ban is active and monitoring
- [ ] smartd test email was received
- [ ] Backup test completed successfully
- [ ] All family members have accounts on relevant services
- [ ] Passwords changed from defaults on all services
- [ ] Management script is accessible
- [ ] Service URLs are documented and shared with family

---

## 🎓 Learn More

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Jellyfin Docs: https://jellyfin.org/docs/
- AdGuard Home Wiki: https://github.com/AdguardTeam/AdGuardHome/wiki
- Uptime Kuma: https://github.com/louislam/uptime-kuma
- Paperless-ngx: https://docs.paperless-ngx.com/

---

## 🎉 Next Steps

1. **Customize Homepage** - Add family-specific links and widgets
2. **Setup Mobile Apps** - Install Jellyfin, Nextcloud, Paperless apps
3. **Configure Parental Controls** - Fine-tune AdGuard for kids' devices
4. **Enable Optional Services** - Try Vaultwarden or Grafana
5. **Create Family Accounts** - Set up individual user accounts on all services
6. **Document Your Setup** - Keep notes on customizations
7. **Share with Family** - Show them how to access all the new services!

---

**Congratulations! Your homeserver is now a feature-rich, secure, family-friendly powerhouse!** 🎊

*For detailed information about each service, see NEW_FEATURES.md*
