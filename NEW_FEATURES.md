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
