# 🔧 NixOS Config Fixes - Action Checklist

*Quick reference for implementing review recommendations*

---

## 🚨 Critical Fixes (Do Immediately)

### 1. Fix DNS Port Forwarding Bug
**File:** `services/firewall.nix` (lines 45-48)

```nix
# BEFORE (WRONG):
{
  sourcePort = 53;
  proto = "udp";
  destination = "192.168.101.14:22";  # ❌ DNS to SSH?
}

# AFTER (FIXED):
{
  sourcePort = 53;
  proto = "udp";
  destination = "192.168.101.14:53";  # ✅ DNS to DNS
}
```

---

### 2. Disable SSH Password Authentication
**File:** `configuration.nix` (line 163)

```nix
# BEFORE:
PasswordAuthentication = true;

# AFTER:
PasswordAuthentication = false;
```

---

### 3. Fix Transmission RPC Whitelist
**File:** `services/transmission.nix` (line 18)

```nix
# BEFORE:
rpc-whitelist = "*";

# AFTER:
rpc-whitelist = "127.0.0.1";  # Only localhost (Caddy proxies)
```

---

### 4. Add Missing Firewall Ports
**File:** `services/firewall.nix` (line 11)

```nix
# BEFORE:
allowedTCPPorts = [ 80 443 1337 8000 8022 8023 8024 8080 8200 5432];

# AFTER:
allowedTCPPorts = [ 80 443 1337 8000 8022 8023 8024 8025 8026 8080 8200 5432];
#                                                      ^^^^ ^^^^ ADDED
```

---

### 5. Fix Configuration Typo
**File:** `configuration.nix` (line 1)

```nix
# BEFORE:
{ config, pkgs, lib, input, ... }:
#                      ^^^^^ TYPO

# AFTER:
{ config, pkgs, lib, inputs, ... }:
#                      ^^^^^^ FIXED (or remove if unused)
```

---

## ⚠️ Security Improvements

### 6. Move Caddy Passwords to agenix
**File:** `services/caddy.nix`

**Steps:**
1. Create encrypted password files:
   ```bash
   echo -n "your_bcrypt_hash" | agenix -e secrets/caddy_mlc.age
   echo -n "your_bcrypt_hash" | agenix -e secrets/caddy_vlp.age
   ```

2. Add to `configuration.nix`:
   ```nix
   age.secrets.caddy_mlc = {
     file = ./secrets/caddy_mlc.age;
     owner = "caddy";
     group = "caddy";
   };
   ```

3. Update `caddy.nix`:
   ```nix
   virtualHosts."new-dl.vlp.fdn.fr".extraConfig = ''
     basic_auth {
       mlc {file.${config.age.secrets.caddy_mlc.path}}
     }
     reverse_proxy http://localhost:9091
   '';
   ```

---

### 7. Add NFS Mount Error Handling
**File:** `configuration.nix` (lines 190-225)

```nix
# BEFORE:
fileSystems."/mnt/animations" = {
  device = "192.168.1.10:/data/animations";
  fsType = "nfs";
};

# AFTER:
fileSystems."/mnt/animations" = {
  device = "192.168.1.10:/data/animations";
  fsType = "nfs";
  options = [ 
    "x-systemd.automount" 
    "noauto" 
    "x-systemd.idle-timeout=600" 
  ];
};
```

*Apply this pattern to all 9 NFS mounts*

---

### 8. Improve Backup Error Handling
**File:** `configuration.nix` (lines 262-280)

```nix
# BEFORE:
systemd.services."backup_nc" = {
  script = ''
    ${pkgs.rsync}/bin/rsync -r -t -x --progress --del /var/lib/nextcloud/data/ /root/backup/nextcloud >> /var/log/timer_nc.log
  '';
  ...
};

# AFTER:
systemd.services."backup_nc" = {
  script = ''
    set -e  # Exit on error
    ${pkgs.rsync}/bin/rsync -a --delete \
      /var/lib/nextcloud/data/ \
      /root/backup/nextcloud/ \
      2>&1 | ${pkgs.coreutils}/bin/tee -a /var/log/timer_nc.log
    echo "[$(date)] Backup completed successfully" >> /var/log/timer_nc.log
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
  onFailure = [ "status-email-root@%n.service" ];  # Email on failure
};
```

---

## 🧹 Code Quality Fixes

### 9. Remove Empty Headscale Module
**Option A:** Delete the file and remove import
```bash
rm services/headscale.nix
```

**File:** `configuration.nix` (line 13)
```nix
# REMOVE THIS LINE:
./services/headscale.nix
```

**Option B:** Add actual configuration if you plan to use it

---

### 10. Format Code
```bash
# Install formatter
nix-shell -p nixpkgs-fmt

# Format all .nix files
nixpkgs-fmt .
```

---

### 11. Remove Commented Code
**Files to clean:** `home.nix`, `nextcloud.nix`, `configuration.nix`

Remove these lines:
- `home.nix` line 9: `#weechat`
- `home.nix` lines 19-21: Commented age secrets
- `nextcloud.nix` line 48: Commented occ command
- `configuration.nix` line 249: Commented `Persistent`

*If you need them later, Git remembers!*

---

## 📚 Documentation

### 12. Update README.md
**File:** `README.md`

Replace current content with:
```markdown
# 🏠 NixOS Maison Configuration

Home server configuration for `maison.vlp.fdn.fr` running NixOS 24.11.

## Services

- 🌩️ **Nextcloud 31** - Personal cloud storage (nuage.vlp.fdn.fr)
- 📥 **Transmission** - BitTorrent client (new-dl.vlp.fdn.fr)
- 📊 **Prometheus** - System monitoring (→ Grafana Cloud)
- 🎬 **MiniDLNA** - Media streaming server
- 🔒 **Headscale** - Self-hosted Tailscale control server (planned)

## Quick Start

### Deploy Configuration
\`\`\`bash
nixos-rebuild switch --flake .#maison
\`\`\`

### Update Flake Inputs
\`\`\`bash
nix flake update
nixos-rebuild switch --flake .#maison
\`\`\`

## Structure

\`\`\`
.
├── configuration.nix       # Main system config
├── hardware-configuration.nix
├── home.nix                # Home-manager config for user 'vlp'
├── flake.nix               # Flake definition
├── services/               # Modular service configurations
│   ├── firewall.nix
│   ├── caddy.nix
│   ├── nextcloud.nix
│   ├── prom.nix
│   └── ...
└── secrets/                # Encrypted secrets (agenix)
\`\`\`

## Secrets Management

Secrets are encrypted with [agenix](https://github.com/ryantm/agenix).

### Edit a Secret
\`\`\`bash
agenix -e secrets/nextcloud.age
\`\`\`

### Add a New Secret
1. Create the secret file
2. Add to `configuration.nix`:
   \`\`\`nix
   age.secrets.mySecret = {
     file = ./secrets/mySecret.age;
     owner = "user";
     group = "group";
   };
   \`\`\`

## Backups

- **Nextcloud data**: `/var/lib/nextcloud/data/` → `/root/backup/nextcloud/` (daily 4 AM)
- **Remote backup**: `new-azul.vlp.fdn.fr:/home/vlp/backup_maison/` (daily 5 AM)

## Network

- **Static IP**: 192.168.1.42
- **Gateway**: 192.168.1.1
- **DNS**: 1.1.1.1
- **VPN**: OpenVPN (FDN)

## Notes

- NFS mounts from 192.168.1.10 (NAS)
- SSH on port 1337 (key-only authentication)
- Firewall: nftables enabled

## License

Personal configuration - use at your own risk.
\`\`\`

---

### 13. Add .gitignore
**Create:** `.gitignore`

```gitignore
# Nix build results
result
result-*

# Logs
*.log

# Temporary files
*.tmp
*.swp
*~

# Secrets (unencrypted)
secrets/*.key
secrets/*_unencrypted

# Virtual machines
*.qcow2

# Development
.direnv
.envrc
```

---

## 🎯 Optional Improvements

### 14. Deduplicate Caddy Config
**File:** `services/caddy.nix`

Replace lines 27-38 with:
```nix
services.caddy.virtualHosts = builtins.listToAttrs (
  map (host: {
    name = host;
    value.extraConfig = ''reverse_proxy 192.168.101.11:80'';
  }) [
    "web.vlp.fdn.fr"
    "farfadet.web.vlp.fdn.fr"
    "cv.web.vlp.fdn.fr"
    "ai.web.vlp.fdn.fr"
  ]
);
```

---

### 15. Split Large Config Files
**Consider creating:**
- `nfs-mounts.nix` - All NFS filesystem declarations
- `backups.nix` - Backup timer and service definitions
- `users.nix` - User and group definitions

---

## ✅ Testing After Changes

After applying fixes, run:

```bash
# 1. Check syntax
nixos-rebuild dry-build --flake .#maison

# 2. Test in VM (optional)
nixos-rebuild build-vm --flake .#maison
./result/bin/run-maison-vm

# 3. Apply changes
sudo nixos-rebuild switch --flake .#maison

# 4. Verify services
systemctl status nextcloud-setup
systemctl status transmission
systemctl status prometheus
systemctl status caddy
```

---

## 📞 Need Help?

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Home Manager: https://nix-community.github.io/home-manager/
- agenix: https://github.com/ryantm/agenix

---

**Last Updated:** 2026-02-11  
**Review Document:** See `REVIEW.md` for detailed analysis
