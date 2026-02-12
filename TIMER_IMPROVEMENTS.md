# 🔧 Timer Improvements Implementation

*"We've taken your timers from 'works most of the time' to 'works like a Swiss watch'—minus the ticking."*

---

## 📋 Summary of Changes

Based on **Chapter 12** of the REVIEW.md, the timer configurations have been significantly improved and refactored into a dedicated module for better organization, error handling, and logging.

---

## 🎯 What Was Fixed

### 1. **Created Dedicated Timer Module** 📦
- **New file:** `services/timers.nix`
- **Why:** Separates timer logic from the main configuration, making it easier to maintain and understand
- **Result:** Clean separation of concerns—like organizing your toolbox instead of throwing everything in one drawer

### 2. **Systemd Journal Logging** 📊
- **Old approach:** Appending to `/var/log/timer_nc.log` indefinitely (file grows forever)
- **New approach:** Using systemd's built-in journal via `echo` statements
- **Why this is better:**
  - Automatic log rotation (no more infinitely growing log files)
  - Centralized logging with `journalctl`
  - Timestamp and metadata automatically added
  - Query logs easily: `journalctl -u backup_nc.service`

### 3. **Error Handling** 🛡️
- **Added:** `set -e` to all scripts (exit immediately on any error)
- **Added:** Clear error messages (e.g., "ERROR: Failed to fetch public IP")
- **Added:** Exit codes for proper failure detection
- **Why:** No more silent failures—if something breaks, you'll know about it

### 4. **IP Change Detection** 🔍
**This was the BIG improvement!**

**Old behavior:**
- Sent email with IP address **every single day** at 2 AM
- Always sent, even if IP hadn't changed
- Noisy and not actionable

**New behavior:**
- Checks IP **every 2 hours** (more responsive)
- **Only sends email when IP actually changes**
- Stores last known IP in `/var/lib/my_ip/last_ip`
- Sends initial notification on first run
- Much cleaner and actionable notifications

### 5. **Added `Persistent` Option** ⏰
- **What it does:** If the system is off when a timer should run, it will run on next boot
- **Example:** If your daily backup at 4 AM is missed because the system was off, it runs when you boot up
- **Why:** Ensures backups never get missed due to downtime

---

## 📝 How to Use These Timers

### View Timer Status
```bash
# Check if timers are active
systemctl list-timers

# Should show:
# NEXT                         LEFT          LAST                         PASSED       UNIT                  ACTIVATES
# Thu 2026-02-13 04:00:00 CET  14h left      Wed 2026-02-12 04:00:00 CET  9h ago       backup_nc.timer       backup_nc.service
# Thu 2026-02-13 05:00:00 CET  15h left      Wed 2026-02-12 05:00:00 CET  8h ago       remote_backup_nc.timer remote_backup_nc.service
# Wed 2026-02-12 16:00:00 CET  2h 0min left  Wed 2026-02-12 14:00:00 CET  9min ago     my_ip.timer           my_ip.service
```

### View Logs
```bash
# View backup logs
journalctl -u backup_nc.service
journalctl -u remote_backup_nc.service

# View IP monitoring logs
journalctl -u my_ip.service

# Follow logs in real-time
journalctl -fu backup_nc.service

# View logs from last 24 hours
journalctl -u backup_nc.service --since "24 hours ago"
```

### Manually Trigger a Service
```bash
# Test backup service manually
systemctl start backup_nc.service

# Test IP check manually
systemctl start my_ip.service

# Check status
systemctl status backup_nc.service
```

### Check IP State File
```bash
# See what IP is currently stored
cat /var/lib/my_ip/last_ip

# Example output:
# 203.0.113.42
```

---

## 🔧 Configuration Details

### Backup Schedule
- **Local Backup:** Daily at 4:00 AM
- **Remote Backup:** Daily at 5:00 AM (runs after local backup completes)

### IP Monitoring Schedule
- **Frequency:** Every 2 hours
- **Behavior:** Only sends email on IP change
- **State File:** `/var/lib/my_ip/last_ip`

---

## 🚀 Advanced Features (Optional)

### Enable Failure Notifications
To get notified when a backup fails, uncomment the `onFailure` line in `services/timers.nix`:

```nix
systemd.services."backup_nc" = {
  # ... existing config ...
  onFailure = [ "backup-failure-notification.service" ];
};
```

Then create the notification service:

```nix
systemd.services."backup-failure-notification" = {
  script = ''
    echo "Subject: Backup Failed on Maison
From: maison@vlp.fdn.fr
To: thomas@criscione.fr

A backup job has failed on maison.
Please check the logs with: journalctl -u backup_nc.service
" | ${pkgs.msmtp}/bin/msmtp thomas@criscione.fr
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
};
```

---

## 🎓 What You Learned

1. **Systemd journal > manual log files**: Let systemd handle logging for you
2. **State management**: Use files to track state between runs (like IP addresses)
3. **Smart notifications**: Only alert when something actually changes
4. **Error handling**: Always use `set -e` and proper error messages
5. **Modularity**: Separate concerns into dedicated files

---

## 🐛 Troubleshooting

### Backup not running?
```bash
# Check timer is enabled
systemctl status backup_nc.timer

# Check for errors
journalctl -u backup_nc.service --since "today"

# Manually trigger to test
systemctl start backup_nc.service
```

### IP not being tracked?
```bash
# Check state directory exists
ls -ld /var/lib/my_ip

# Check service logs
journalctl -u my_ip.service

# Manually trigger to test
systemctl start my_ip.service
```

### Not receiving emails?
```bash
# Test msmtp configuration
echo "test" | msmtp thomas@criscione.fr

# Check service has correct path
systemctl show my_ip.service | grep PATH
```

---

## 📚 References

- **REVIEW.md Chapter 12:** Original issue identification
- **systemd.timer(5):** `man systemd.timer`
- **systemd.service(5):** `man systemd.service`
- **journalctl(1):** `man journalctl`

---

## 🎬 Final Thoughts

*"These timers are now like a good butler—quiet, efficient, and only speak up when something important happens. Your inbox will thank you."*

The improvements made here follow NixOS and systemd best practices:
- ✅ Proper error handling
- ✅ Smart notifications (signal vs. noise)
- ✅ Centralized logging
- ✅ Modular configuration
- ✅ State management
- ✅ Persistent timers (no missed backups)

Your timer game just leveled up from "adequate" to "production-grade." 🚀

---

**Implementation Date:** 2026-02-12  
**Author:** botbot (your friendly neighborhood NixOS mentor)  
**Status:** ✅ Complete and ready to deploy
