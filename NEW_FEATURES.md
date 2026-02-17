# 🚀 New Services & Features Guide

## Overview

This guide covers the new services added to improve security, family-friendliness, and functionality of your homeserver.

---

## 🛡️ Security Enhancements

### 1. fail2ban - Intrusion Prevention

**What it does:** Automatically bans IP addresses that show malicious behavior (repeated failed login attempts).

**Protected Services:**
- SSH (port 1337) - Max 3 attempts
- Caddy basic auth (ports 80/443) - Max 5 attempts

**Ban Policy:**
- Initial ban: 1 hour
- Progressive bans: Doubles with each offense (max 1 week)
- Local networks (192.168.x.x, Headscale) are whitelisted

**Check banned IPs:**
```bash
sudo fail2ban-client status sshd
sudo fail2ban-client status caddy-auth
```

**Unban an IP manually:**
```bash
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

---

### 2. smartd - Disk Health Monitoring

**What it does:** Monitors disk health using S.M.A.R.T. and sends email alerts if problems detected.

**Features:**
- Daily short self-tests at 2 AM
- Weekly long self-tests on Saturdays at 3 AM
- Automatic email alerts to monitoring@vlp.fdn.fr

**Check disk health:**
```bash
sudo smartctl -a /dev/sda
sudo smartctl -H /dev/sdb  # Quick health check
```

**View test logs:**
```bash
sudo smartctl -l selftest /dev/sda
```

---

### 3. Automatic Security Updates

**What it does:** Automatically updates NixOS weekly with security patches.

**Schedule:**
- Weekly on Sundays at 3 AM
- Auto-reboot if needed (between 3-5 AM)
- Email notification sent on completion/failure

**Manual update:**
```bash
sudo nixos-rebuild switch --flake /home/vlp/nixos_maison#maison
```

**Check update history:**
```bash
journalctl -u nixos-upgrade.service -n 100
```

---

## 🎮 Family-Friendly Services

### 4. Jellyfin - Modern Media Server

**What it does:** Netflix-like interface for movies, TV shows, and music.

**Access:** 
- Web: http://192.168.1.42:8096 or https://media.vlp.fdn.fr
- Apps available for:
  - Android/iOS phones and tablets
  - Smart TVs (Samsung, LG, Roku, Fire TV)
  - Apple TV, Android TV
  - Desktop apps for Windows/Mac/Linux

**First-time setup:**
1. Open http://192.168.1.42:8096
2. Create admin account
3. Add media libraries:
   - Movies: `/mnt/movies`
   - TV Shows: `/mnt/tvshows`
   - Animations: `/mnt/animations`
   - Music: `/mnt/audio`
   - Documentaries: `/mnt/docu`

**Advantages over DLNA:**
- Remote access via web/apps
- User profiles for each family member
- Continue watching functionality
- Parental controls
- Subtitle support
- Watch history and recommendations

---

### 5. AdGuard Home - Network Ad Blocker

**What it does:** Blocks ads, trackers, and malicious sites for ALL devices on your network.

**Access:** http://192.168.1.42:3000

**First-time setup:**
1. Open http://192.168.1.42:3000
2. Follow setup wizard
3. Create admin account
4. **IMPORTANT:** Configure your router or devices to use `192.168.1.42` as DNS server

**Features:**
- Blocks ads on phones, tablets, smart TVs (even in apps!)
- Parental controls (block adult content, social media, etc.)
- Safe browsing (blocks malware/phishing sites)
- Per-device rules (different filtering for kids vs adults)
- Query logs (see what domains are being accessed)

**Parental Control Setup:**
1. Go to Settings → General Settings
2. Enable "Parental Control"
3. Go to Filters → DNS Blocklists
4. Add family-friendly filters

**Recommended Usage:**
- Set router DNS to 192.168.1.42 for network-wide protection
- Or manually configure each device to use 192.168.1.42 as DNS

---

### 6. Homepage Dashboard - Family Portal

**What it does:** Beautiful landing page with links to all services.

**Access:** https://home.vlp.fdn.fr

**Features:**
- One-stop access to all services
- System resource monitoring (CPU, RAM, disk)
- Clock and date
- Responsive design (works on phones/tablets)

**Customization:**
Edit `/home/runner/work/nixos_maison/nixos_maison/services/homepage.nix` to:
- Add new services
- Change layout
- Modify widgets

---

## 📊 Monitoring & Management

### 7. Uptime Kuma - Service Monitoring

**What it does:** Monitors all services and alerts you if something goes down.

**Access:** https://status.vlp.fdn.fr

**First-time setup:**
1. Open https://status.vlp.fdn.fr
2. Create admin account
3. Add monitors for each service

**Recommended monitors:**
- HTTP checks for Nextcloud, Jellyfin, etc.
- Ping checks for local devices
- Port checks for SSH, Headscale
- Certificate expiration monitoring

**Features:**
- Email/SMS/Telegram notifications
- Status page (share with family)
- Uptime statistics
- Response time graphs

---

### 8. Paperless-ngx - Document Management

**What it does:** Digital archive for all your family documents with OCR and full-text search.

**Access:** https://docs.vlp.fdn.fr

**First-time setup:**
1. Open https://docs.vlp.fdn.fr
2. Create admin account
3. Configure document sources

**Features:**
- Automatic OCR (English + French)
- Full-text search
- Tags and custom fields
- Email import (scan-to-email from your printer)
- Mobile app (scan with phone camera)
- Automatic file organization

**Auto-import folder:** `/var/lib/paperless/consume`
- Any PDF/image dropped here gets automatically imported

**Use cases:**
- Scan receipts, invoices, contracts
- Digitize old family documents
- Store insurance papers, manuals, warranties
- Search by content (e.g., "find contract from 2020")

**Scanner integration:**
Configure your Epson scanner to save to `/var/lib/paperless/consume/` via NFS.

---

## 🔧 Maintenance

### Automatic Garbage Collection

Old NixOS generations are automatically cleaned up weekly (keeps last 30 days).

**Manual cleanup:**
```bash
sudo nix-collect-garbage --delete-older-than 30d
sudo nix-store --optimize
```

### Service Status Checks

**Check all new services:**
```bash
systemctl status fail2ban
systemctl status adguardhome
systemctl status jellyfin
systemctl status homepage-dashboard
systemctl status smartd
systemctl status uptime-kuma
systemctl status paperless-web
```

**View service logs:**
```bash
journalctl -u jellyfin -f
journalctl -u adguardhome -f
```

---

## 🎯 Quick Start Guide for Family

### For Media Consumption:

1. **Jellyfin** (https://media.vlp.fdn.fr)
   - Download app on phone/TV
   - Login with your account
   - Start watching!

2. **AdGuard Home** (http://192.168.1.42:3000)
   - Admin configures DNS on router
   - Ads disappear automatically on all devices

### For File Management:

3. **Nextcloud** (https://nuage.vlp.fdn.fr)
   - Upload files via web or app
   - Share with family members

4. **Paperless** (https://docs.vlp.fdn.fr)
   - Scan documents with phone
   - Upload directly to website
   - Search and retrieve anytime

### For Downloads:

5. **Transmission** (https://dl.vlp.fdn.fr)
   - Add torrent files or magnet links
   - Downloads appear in Jellyfin automatically

---

## 🔐 Security Best Practices

1. **Change default passwords:** All services require password setup on first access
2. **Enable 2FA:** Where available (Nextcloud, Paperless)
3. **Regular backups:** Already configured! Check backup logs: `journalctl -u backup_nc`
4. **Monitor alerts:** Check monitoring@vlp.fdn.fr for system notifications
5. **Review fail2ban logs:** `sudo fail2ban-client status`

---

## 📱 Mobile Apps

- **Jellyfin:** Official apps on iOS/Android
- **Nextcloud:** Official apps on iOS/Android
- **Paperless:** Android app available
- **AdGuard Home:** Admin via web browser
- **Uptime Kuma:** Admin via web browser

---

## 🆘 Troubleshooting

### Service won't start?
```bash
sudo systemctl status <service-name>
journalctl -u <service-name> -n 50
```

### Can't access web interface?
1. Check if service is running: `systemctl status <service>`
2. Check firewall: `sudo nft list ruleset`
3. Check Caddy: `journalctl -u caddy -n 50`

### AdGuard not blocking ads?
1. Verify DNS settings: `nslookup google.com 192.168.1.42`
2. Check device DNS configuration
3. Some apps use hardcoded DNS (can't be blocked)

### Jellyfin transcoding issues?
- Check CPU usage: `htop`
- Consider enabling hardware acceleration in Jellyfin settings
- Reduce quality settings for older devices

---

## 📈 Resource Usage

Estimated additional resource requirements:
- **CPU:** +10-15% average (mostly Jellyfin transcoding)
- **RAM:** +2-3 GB (Jellyfin, Paperless, Redis)
- **Disk:** +5-10 GB for service data
- **Network:** Minimal (mostly outbound updates)

---

## 🎉 Next Steps

1. **Configure AdGuard Home** - Set up DNS on your router
2. **Setup Jellyfin** - Add your media libraries
3. **Create Uptime Kuma monitors** - Monitor all services
4. **Test Paperless** - Scan a test document
5. **Customize Homepage** - Add links to your favorite sites
6. **Share with family** - Create accounts for each family member

**Remember:** All these services are designed to make your homeserver more useful and easier to use for the whole family. Take your time setting them up, and enjoy! 🏠✨

---

## 🎁 Optional Services (Ready to Enable)

The following services are pre-configured but disabled by default. To enable any of them, uncomment the corresponding line in `configuration.nix` and the Caddy reverse proxy entry in `services/caddy.nix`.

### 9. Vaultwarden - Family Password Manager 🔐

**What it does:** Self-hosted Bitwarden-compatible password manager for family password sharing.

**Access:** https://vault.vlp.fdn.fr (when enabled)

**Why use it:**
- Share WiFi passwords, streaming service logins with family
- Secure password generator
- Browser extensions for all major browsers
- Mobile apps for iOS/Android
- End-to-end encryption
- Free (no subscription needed)
- TOTP 2FA generator built-in

**Enable:**
1. Uncomment `./services/vaultwarden.nix` in `configuration.nix`
2. Uncomment the Caddy virtualHost for `vault.vlp.fdn.fr`
3. Rebuild: `sudo nixos-rebuild switch --flake .#maison`
4. Access https://vault.vlp.fdn.fr and create admin account
5. Disable public signups (already configured)
6. Invite family members via admin panel

**Automatic backups:** Daily at 2 AM with 30-day retention

---

### 10. Calibre-web - Digital Library 📚

**What it does:** Manage and read ebooks online with conversion support.

**Access:** https://books.vlp.fdn.fr (when enabled)

**Features:**
- Web-based ebook reader
- Format conversion (EPUB, MOBI, PDF, etc.)
- Sync with e-readers (Kindle, Kobo)
- Search by title, author, series
- Reading progress tracking
- Send to Kindle/email

**Enable:**
1. Uncomment `./services/calibre-web.nix` in `configuration.nix`
2. Uncomment the Caddy virtualHost for `books.vlp.fdn.fr`
3. Rebuild system
4. Import existing ebooks from `/mnt/ebooks` if available

---

### 11. FreshRSS - RSS Feed Reader 📰

**What it does:** Stay updated with news, blogs, and YouTube channels in one place.

**Access:** https://rss.vlp.fdn.fr (when enabled)

**Features:**
- Subscribe to unlimited RSS/Atom feeds
- YouTube channel subscriptions (ad-free!)
- Mobile apps available
- Keyword filtering and search
- Read later / favorites
- Offline reading support

**Use cases:**
- Follow tech blogs, news sites
- YouTube subscriptions without ads
- Monitor GitHub releases, package updates
- Track weather forecasts

---

### 12. PhotoPrism - AI Photo Management 📸

**What it does:** Google Photos alternative with AI-powered photo organization.

**Access:** https://photos.vlp.fdn.fr (when enabled)

**Features:**
- Automatic face recognition
- Location tagging with maps
- Object/scene detection (AI)
- RAW photo support
- Video support with transcoding
- Timeline view
- Albums and sharing
- Mobile apps

**Note:** Resource-intensive (requires ~2GB RAM). Consider linking to Nextcloud photos folder for automatic indexing.

---

### 13. Grafana - Local Monitoring Dashboard 📊

**What it does:** Beautiful local monitoring dashboard with pre-configured system metrics.

**Access:** https://grafana.vlp.fdn.fr (when enabled)

**Features:**
- Pre-connected to Prometheus
- Node Exporter dashboard auto-installed
- Anonymous read-only access for family
- Real-time CPU, memory, disk, network graphs
- Historical data analysis
- Custom alerting

**Great for:**
- Checking system load before starting a backup
- Troubleshooting performance issues
- Showing off your homeserver stats 😎

---

### 14. Restic - Versioned Encrypted Backups 💾

**What it does:** Encrypted, deduplicated, versioned backups of critical data.

**Features:**
- End-to-end encryption
- Deduplication (saves space)
- Multiple snapshots with retention policies
- Fast incremental backups
- Backup verification

**Pre-configured backups:**
- Nextcloud data (daily at 3:30 AM)
- Vaultwarden passwords (daily at 3:45 AM)
- System config (weekly)

**Retention policy:**
- Daily backups: 7-14 days
- Weekly backups: 4-8 weeks
- Monthly backups: 6-12 months
- Yearly backups: 2 years (system config)

**Manual operations:**
```bash
# List snapshots
restic -r /root/backup/restic/nextcloud snapshots

# Restore a file
restic -r /root/backup/restic/nextcloud restore latest --target /tmp/restore --include /path/to/file

# Check backup integrity
restic -r /root/backup/restic/nextcloud check
```

---

## 🎯 Recommended Activation Order

If you want to enable optional services, here's the suggested order:

1. **Vaultwarden** (password manager) - Most useful, low resource usage
2. **Grafana** (monitoring) - Helpful for understanding system performance
3. **Restic** (versioned backups) - Important for data safety
4. **FreshRSS** (RSS reader) - Light and useful for staying informed
5. **Calibre-web** (ebooks) - If you have ebook collection
6. **PhotoPrism** (photos) - If Nextcloud Photos isn't enough (resource-heavy)

---

## 📊 Total Resource Usage (All Services)

If you enable ALL services, expect:

- **CPU:** +20-30% average (PhotoPrism indexing can spike to 100%)
- **RAM:** +4-6 GB (PhotoPrism is the hungriest)
- **Disk:** +10-20 GB for service data (+ backup space)
- **Network:** Minimal impact

**Recommendation:** Enable services gradually and monitor with Grafana!

---

## 🔒 Security Checklist (Updated)

With all the new services, here's what to secure:

- [ ] Change all default admin passwords on first login
- [ ] Enable 2FA where available (Nextcloud, Vaultwarden, Grafana)
- [ ] Review fail2ban logs weekly: `sudo fail2ban-client status`
- [ ] Configure AdGuard Home parental controls if kids use the network
- [ ] Disable public signups on all services (already done in configs)
- [ ] Set up Vaultwarden admin token via environment variable
- [ ] Regular backup testing: Restore a file from restic monthly
- [ ] Monitor disk health alerts: Check monitoring@vlp.fdn.fr
- [ ] Review Uptime Kuma alerts for service downtime
- [ ] Update PhotoPrism admin password after setup

---

## 💡 Pro Tips

1. **Homepage Dashboard Customization:**
   Edit `services/homepage.nix` to add custom links, weather widgets, or service integrations.

2. **AdGuard Home Advanced:**
   - Create device-specific DNS rules (kids' devices vs adults)
   - Schedule "internet bedtime" via parental controls
   - Block social media during work hours

3. **Jellyfin Hardware Acceleration:**
   If you have Intel GPU, uncomment hardware acceleration in `services/jellyfin.nix` for butter-smooth transcoding.

4. **Vaultwarden for TOTP:**
   Use it as authenticator app replacement (generates 2FA codes for other services).

5. **FreshRSS + YouTube:**
   Subscribe to YouTube channels via RSS (no ads, no algorithm, no tracking!).
   Format: `https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`

6. **PhotoPrism Performance:**
   Disable face recognition if you don't need it (saves CPU/RAM).

7. **Restic Remote Backup:**
   Extend restic configs to backup to remote location (S3, Backblaze B2, etc.) for off-site backup.

---

## 🆘 Common Issues & Solutions

### "Service won't start after enabling"
```bash
# Check service status
systemctl status service-name

# View detailed logs
journalctl -u service-name -n 100 --no-pager

# Check configuration errors
nixos-rebuild dry-build --flake .#maison
```

### "Can't access web interface"
1. Verify service is running: `systemctl status service-name`
2. Check Caddy is proxying: `journalctl -u caddy -n 50`
3. Test direct access: `curl http://127.0.0.1:PORT`
4. Check firewall: `sudo nft list ruleset | grep PORT`

### "Vaultwarden login fails"
- Check logs: `journalctl -u vaultwarden -n 50`
- Ensure DOMAIN setting matches your URL
- Clear browser cache and cookies

### "PhotoPrism indexing is slow"
- This is normal for first import
- Check CPU usage: `htop`
- Consider reducing workers in config
- Let it run overnight for large collections

### "Restic backup failed"
- Check email alert from monitoring@vlp.fdn.fr
- Verify LUKS disk is mounted: `mountpoint /root/backup`
- Check logs: `journalctl -u restic-backups-nextcloud-local -n 50`
- Manual test: `restic -r /root/backup/restic/nextcloud snapshots`

---

## 🎊 You're All Set!

Your family homeserver is now a powerhouse of functionality! You've got:

- 🎬 Media streaming (Jellyfin + DLNA)
- 📁 File storage (Nextcloud)
- 🔐 Password management (Vaultwarden - optional)
- 📰 News & feeds (FreshRSS - optional)
- 📚 Ebook library (Calibre-web - optional)
- 📸 Photo management (PhotoPrism - optional)
- 🛡️ Network security (fail2ban + AdGuard)
- 📊 Monitoring (Prometheus + Grafana + Uptime Kuma)
- 💾 Multiple backup strategies
- 🚀 Automatic updates
- 📄 Document management (Paperless)
- 🏠 Family portal (Homepage)

**Pro tip:** Print out the service URLs and stick them on the fridge for family reference! 📝

---

**Questions? Issues? Improvements?**

Check the logs, consult the NixOS manual, or review the service-specific documentation. Remember: *"The goal isn't just to fix your config—it's to make you a NixOS ninja!"* 🥷

---

*Last updated: February 2026*
