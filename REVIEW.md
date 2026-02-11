# 🔍 NixOS Configuration Global Review

*"Your config is like a Swiss Army knife—packed with features, but let's make sure none of the blades are rusty."* 

---

## 📊 Executive Summary

**Overall Status:** ⚠️ **Good with improvements needed**

Your NixOS configuration is functional and well-organized, but there are several areas that need attention—especially around security, error handling, and code consistency. Think of this review as preventive maintenance: your ship is sailing, but a few patches will keep it from taking on water.

---

## 🚨 Critical Issues (Must Fix)

### 1. **Typo in `configuration.nix` Line 1** ⚠️
```nix
{ config, pkgs, lib, input, ... }:
#                      ^^^^^ Should be "inputs"
```
**Problem:** You're declaring an unused parameter `input` (singular) instead of `inputs` (plural). This is inconsistent with flake conventions and could cause confusion.

**Fix:**
```nix
{ config, pkgs, lib, inputs, ... }:
```

**Note:** If you're not actually using `inputs`, remove it entirely to keep the signature clean.

---

### 2. **Hardcoded Password Hashes in Caddy Config** 🔐
**File:** `services/caddy.nix` (lines 11, 20)

**Problem:** You're embedding bcrypt password hashes directly in your configuration. While better than plaintext, these should be managed via `agenix` like your other secrets.

**Current:**
```nix
basic_auth {
  mlc $2a$14$qDVVV0r7JB8QyhswO2/x1utmcYn7XJmMlCE/66hEWdr78.jjmE3Sq
}
```

**Recommendation:**
1. Store hashed passwords in `agenix`
2. Reference them via `config.age.secrets.caddy_auth.path`
3. Use Caddy's `basicauth` directive with file references

**Why:** Hashes in version control can be brute-forced offline. Treat them like passwords.

---

### 3. **OpenVPN Config Path Hardcoded** 📁
**File:** `configuration.nix` (line 173)

**Problem:**
```nix
services.openvpn.servers = {
  officeVPN  = { config = '' config /root/fdn.conf ''; };
};
```

**Issues:**
- Hardcoded path to `/root/fdn.conf` (not reproducible, not in the Nix store)
- VPN config should be managed via `agenix` or imported from the Nix store

**Fix:** Either:
1. Import the config file into your repo (if not sensitive): `config = builtins.readFile ./vpn/fdn.conf;`
2. Use `agenix` to encrypt and manage it

---

### 4. **Firewall: Port Forwarding to Wrong Destination** 🐛
**File:** `services/firewall.nix` (lines 45-48)

```nix
{
  sourcePort = 53;
  proto = "udp";
  destination = "192.168.101.14:22";  # ❌ Port 53 forwarded to SSH port 22?
}
```

**Problem:** You're forwarding UDP port 53 (DNS) to port 22 (SSH) on 192.168.101.14. This makes zero sense unless you're running a DNS server on port 22, which... please don't.

**Fix:** Either:
- Change destination to `192.168.101.14:53` (if Pi-hole runs DNS)
- Remove this rule if it's a mistake

---

### 5. **Missing Port in Firewall `allowedTCPPorts`** 🔓
**File:** `services/firewall.nix` (line 11)

You're allowing port `8025` in firewall rules (line 35-38 in the NAT config), but it's **not listed** in `allowedTCPPorts`. This might block the connection unless the NAT rule is working differently than expected.

**Add:**
```nix
allowedTCPPorts = [ 80 443 1337 8000 8022 8023 8024 8025 8026 8080 8200 5432];
```

---

## ⚠️ Security Concerns

### 6. **SSH Password Authentication Enabled** 🔑
**File:** `configuration.nix` (line 163)

```nix
PasswordAuthentication = true;
```

**Why This Is Bad:** Password auth is vulnerable to brute-force attacks. You already have SSH keys configured (line 65), so password auth is redundant.

**Fix:**
```nix
PasswordAuthentication = false;
```

**Bonus:** You're already using `PermitRootLogin = "prohibit-password"` (line 167), which is good! Just disable password auth for the `vlp` user too.

---

### 7. **Transmission RPC Whitelist Set to `*`** 🌐
**File:** `services/transmission.nix` (line 18)

```nix
rpc-whitelist = "*";
```

**Problem:** This allows **anyone** on your network (or via port forwarding) to access Transmission's RPC interface. Combined with `rpc-bind-address = "0.0.0.0"`, this is a security risk.

**Fix:**
```nix
rpc-whitelist = "127.0.0.1,192.168.1.*";  # Only localhost and LAN
```

Or better yet, rely on Caddy's `basic_auth` and set:
```nix
rpc-whitelist = "127.0.0.1";  # Only localhost (Caddy will proxy)
```

---

## 🎨 Code Quality & Best Practices

### 8. **Inconsistent Formatting** 🧹
**Multiple Files**

Your code has inconsistent indentation and spacing. Examples:
- `firewall.nix`: Uses 2-space indentation
- `caddy.nix`: Inconsistent spacing around braces
- `home.nix`: Mixed tab/space usage (line 33: `editor ="vim";` vs `editor = "vim";`)

**Fix:** Run `nixpkgs-fmt` or `alejandra` to auto-format:
```bash
nix-shell -p nixpkgs-fmt --run "nixpkgs-fmt ."
```

**Storage Note:** Consider adding a formatter check to your CI/CD (if you have one).

---

### 9. **Empty Headscale Module** 🤔
**File:** `services/headscale.nix`

```nix
{
  config,
  pkgs,
  ...
}:
{


}
```

**Problem:** You're importing an empty module. This does nothing and clutters your imports list.

**Fix:** Either:
1. Remove the import from `configuration.nix` (line 13)
2. Or add actual Headscale configuration if you plan to use it

---

### 10. **Commented Code Everywhere** 💬
**Files:** `home.nix`, `nextcloud.nix`, `configuration.nix`

Examples:
- `home.nix` (lines 9, 19-21): Commented `weechat` and age secrets
- `nextcloud.nix` (line 48): Commented occ command
- `configuration.nix` (line 249): Commented `Persistent` timer option

**Problem:** Commented code is like leaving dirty dishes in the sink—it's clutter. If you don't need it, delete it. Git remembers everything anyway.

**Fix:** Remove commented code or add a `TODO:` if you plan to enable it later.

---

### 11. **NFS Mounts Without Error Handling** 📡
**File:** `configuration.nix` (lines 190-225)

**Problem:** You have 9 NFS mounts with no options for retry, timeout, or soft/hard mount behavior. If your NAS (`192.168.1.10`) goes down, boot could hang indefinitely.

**Fix:** Add mount options:
```nix
fileSystems."/mnt/animations" = {
  device = "192.168.1.10:/data/animations";
  fsType = "nfs";
  options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
};
```

**Explanation:**
- `x-systemd.automount`: Mounts on-demand (doesn't block boot)
- `noauto`: Prevents automatic mount at boot
- `x-systemd.idle-timeout=600`: Unmounts after 10 minutes of inactivity

---

### 12. **Backup Scripts Lack Error Handling** 🛡️
**File:** `configuration.nix` (lines 263-280)

**Problems:**
1. No error checking (what if rsync fails?)
2. Logs append indefinitely (`>> /var/log/timer_nc.log` grows forever)
3. Remote backup has no error notification

**Fix:**
```nix
systemd.services."backup_nc" = {
  script = ''
    set -e  # Exit on error
    ${pkgs.rsync}/bin/rsync -a --delete /var/lib/nextcloud/data/ /root/backup/nextcloud/ 2>&1 | tee -a /var/log/timer_nc.log
    echo "Backup completed at $(date)" >> /var/log/timer_nc.log
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
  onFailure = [ "backup-failed-notification.service" ];  # Optional: email on failure
};
```

**Bonus:** Rotate logs with `logrotate` or use systemd's journal instead.

---

### 13. **Timer `my_ip` Has Unclear Purpose** 🕵️
**File:** `configuration.nix` (lines 282-298)

**Problem:** This sends your public IP to `thomas@criscione.fr` daily at 2 AM. While functional, it's unclear:
1. Why you need this (do you have a dynamic IP?)
2. Why not use a dynamic DNS service (e.g., DuckDNS, Cloudflare)?

**Recommendation:** If you need dynamic DNS, use a proper service:
```nix
services.ddclient = {
  enable = true;
  protocol = "cloudflare";
  zone = "example.com";
  username = "your-email@example.com";
  passwordFile = "/path/to/api-token";
};
```

---

## 🚀 Optimization Opportunities

### 14. **Duplicate Caddy Reverse Proxies** 🔄
**File:** `services/caddy.nix` (lines 30-38)

You have 4 virtual hosts pointing to the same backend (`192.168.101.11:80`):
- `web.vlp.fdn.fr`
- `farfadet.web.vlp.fdn.fr`
- `cv.web.vlp.fdn.fr`
- `ai.web.vlp.fdn.fr`

**Why This Matters:** If you change the backend IP or add authentication, you'll need to update 4 places.

**Fix:** Use Caddy's matcher or create a reusable snippet:
```nix
virtualHosts = builtins.listToAttrs (map (host: {
  name = host;
  value.extraConfig = ''reverse_proxy 192.168.101.11:80'';
}) [ "web.vlp.fdn.fr" "farfadet.web.vlp.fdn.fr" "cv.web.vlp.fdn.fr" "ai.web.vlp.fdn.fr" ]);
```

---

### 15. **Nextcloud Preview Generators Could Be Optimized** 🖼️
**File:** `services/nextcloud.nix` (lines 28-40)

**Current:** You're enabling 11 preview providers, which is good! But:
1. Consider adding `"OC\\Preview\\Movie"` if you store videos
2. Consider adding `"OC\\Preview\\PDF"` if you use Nextcloud for documents

**Also:** You have `previewgenerator` in `extraApps` (line 43) but didn't mention running:
```bash
nextcloud-occ preview:generate-all
```

**Recommendation:** Add a systemd timer to periodically generate previews:
```nix
systemd.timers."nextcloud-preview-gen" = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    Unit = "nextcloud-preview-gen.service";
  };
};

systemd.services."nextcloud-preview-gen" = {
  script = ''
    ${config.services.nextcloud.occ}/bin/nextcloud-occ preview:pre-generate
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "nextcloud";
  };
};
```

---

### 16. **Consider Splitting Large Configs** 📂
**File:** `configuration.nix` (309 lines!)

Your main config is getting chunky. Consider splitting:
- NFS mounts → `services/nfs-mounts.nix`
- Backup timers → `services/backups.nix`
- User/group definitions → `users.nix`

**Benefits:**
- Easier to navigate
- Reusable across systems
- Clearer git diffs

---

## 📚 Documentation Improvements

### 17. **README is Minimal** 📖
**File:** `README.md`

**Current:** "nixos conf maison"

**That's it?** Your Tony Stark deserves better documentation! Add:
1. **What this config does** (server? desktop? homelab?)
2. **How to deploy**: `nixos-rebuild switch --flake .#maison`
3. **Services running**: Nextcloud, Transmission, Prometheus, etc.
4. **Secret management**: How to use `agenix`
5. **Backup strategy**: What gets backed up, where, when

**Template:**
```markdown
# NixOS Maison Configuration

Home server configuration running:
- 🌩️ Nextcloud (nuage.vlp.fdn.fr)
- 📥 Transmission (new-dl.vlp.fdn.fr)
- 📊 Prometheus monitoring
- 🔐 Headscale VPN (planned)

## Deployment
\`\`\`bash
nixos-rebuild switch --flake .#maison
\`\`\`

## Secrets
Managed with [agenix](https://github.com/ryantm/agenix).
...
```

---

## 🎯 Recommendations

### 18. **Add a `.gitignore`** 🚫
You don't have one! Add:
```
result
result-*
*.qcow2
*.log
.direnv
```

---

### 19. **Consider State Management Best Practices** 💾
You're using:
- `/root/backup/` for backups
- `/var/lib/nextcloud/data/` mounted via NFS
- `/var/log/timer_nc.log` for logs

**Good:** Stateful data is separated  
**Better:** Document where state lives in your README  
**Best:** Consider using systemd's `StateDirectory` for cleaner management

---

### 20. **Flake Lock is Out of Date?** 🔒
**File:** `flake.lock`

**Question:** When did you last update? Run:
```bash
nix flake update
```

Check for security updates, especially for Nextcloud (`pkgs.nextcloud31`).

---

## ✅ What You're Doing Right

Let's not focus only on problems! Here's what's solid:

1. ✅ **Using Flakes**: Modern, reproducible config
2. ✅ **agenix for secrets**: Encrypted secrets management
3. ✅ **Modular structure**: Services split into separate files
4. ✅ **Home Manager**: User-level config separated
5. ✅ **Automated backups**: Systemd timers for scheduled tasks
6. ✅ **Prometheus monitoring**: Proactive system monitoring
7. ✅ **LUKS encryption**: Disk encryption enabled (hardware-configuration.nix)
8. ✅ **SSH key authentication**: Using YubiKey + ed25519 keys

---

## 🏁 Priority Action Items

### High Priority (Do First)
1. ☐ Fix DNS port forwarding bug (line 45-48, firewall.nix)
2. ☐ Disable SSH password authentication
3. ☐ Fix Transmission RPC whitelist
4. ☐ Add missing port 8025 & 8026 to firewall
5. ☐ Fix typo: `input` → `inputs` (configuration.nix:1)

### Medium Priority (This Week)
6. ☐ Move Caddy passwords to agenix
7. ☐ Add NFS mount error handling
8. ☐ Improve backup error handling
9. ☐ Remove empty headscale.nix or configure it
10. ☐ Format code with `nixpkgs-fmt`

### Low Priority (Nice to Have)
11. ☐ Expand README
12. ☐ Remove commented code
13. ☐ Split large config files
14. ☐ Add `.gitignore`
15. ☐ Optimize Caddy config (DRY principle)

---

## 🎬 Final Thoughts

*"This config is like a well-loved lightsaber—powerful, battle-tested, but in need of maintenance. Let's sharpen that blade."*

Your setup is impressive! You're running a full home server with Nextcloud, monitoring, VPN, DLNA, and automated backups. The modular structure shows you understand NixOS principles.

**Main takeaway:** Focus on security (SSH, Transmission, secrets) and error handling (NFS, backups). Once those are locked down, your config will be production-grade.

Need help implementing any of these fixes? Drop a question, and I'll provide specific code examples. May the Force (and functional programming) be with you! 🚀

---

**Review Date:** 2026-02-11  
**Reviewer:** botbot (your friendly neighborhood NixOS mentor)  
**Config Version:** 24.11
