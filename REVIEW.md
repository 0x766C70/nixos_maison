# 🔍 NixOS Configuration Global Review

*Comprehensive Re-Analysis - April 6, 2026*

---

## 📊 Executive Summary

**Overall Status:** ✅ **Production-Ready Excellence — Leveled Up**

The configuration has continued its upward trajectory. Since the February 2026 review, a substantial wave of improvements has landed: a full fail2ban brute-force defense layer, deep Transmission systemd hardening, Tailscale VPN integration, a headscale control node, a static-site server, automatic torrent pruning, and a channel bump to NixOS 25.11. This is the kind of iterative hardening that separates a "works on my machine" config from something you'd bet production on.

A small handful of low-priority items remain — nothing that threatens stability or security. The full breakdown follows.

---

## 🎉 New Improvements Since February 2026

Outstanding batch of work. Here's what changed:

### ✅ **Channel & Package Updates**

1. **✅ NixOS 25.11**: Flake pinned to `nixos-25.11` / `home-manager release-25.11` (flake.nix:5-8)
2. **✅ Nextcloud 32**: Upgraded from `nextcloud31` to `nextcloud32` (nextcloud.nix:9)
3. **✅ New Nextcloud Apps**: `deck` (kanban) and `recognize` (AI photo tagging) added (nextcloud.nix:45)

### ✅ **Network & VPN**

4. **✅ Tailscale Client**: `services.tailscale` enabled with `useRoutingFeatures = "client"` (configuration.nix:100-103)
5. **✅ Headscale Exposure**: Port 8085 opened in firewall; `hs.vlp.fdn.fr` virtual host added in Caddy (firewall.nix:10, caddy.nix:71-73)

### ✅ **Security — fail2ban**

6. **✅ fail2ban Enabled**: Comprehensive brute-force protection with jails for SSH (port 1337), Caddy basic auth (`dl.vlp.fdn.fr`, `laptop.vlp.fdn.fr`), and Nextcloud login failures (fail2ban.nix)
7. **✅ nftables Integration**: `banaction = "nftables-multiport"` — correct backend for the firewall stack (fail2ban.nix:16)
8. **✅ Custom fail2ban Filters**: Tailored regex filters for Caddy JSON access logs and Nextcloud's structured JSON log format (fail2ban.nix:120-142)
9. **✅ Per-vhost Caddy Logging**: `dl.vlp.fdn.fr` and `laptop.vlp.fdn.fr` now emit structured JSON access logs to dedicated files for fail2ban consumption, with rotation (caddy.nix:27-57)

### ✅ **Caddy Hardening & New Sites**

10. **✅ Eval-time Path Assertion**: `assertions` block catches non-absolute `alicantePath` at eval time, before any disk write (caddy.nix:13-20) — *this is NixOS best practice and most people skip it*
11. **✅ Alicante Static Site**: `alicante.vlp.fdn.fr` serves a static Hugo/file site from `/var/www/alicante/public` with `file_server`, `encode zstd gzip`, and a solid security header block (caddy.nix:74-91)
12. **✅ Directory Provisioning**: `systemd.tmpfiles.rules` provisions `/var/log/caddy`, `/var/www`, and the alicante path with correct Caddy ownership (caddy.nix:99-104)

### ✅ **Transmission Hardening**

13. **✅ systemd Confinement**: `confinement.enable = true` with `full-apivfs` — Transmission now runs in a private filesystem namespace (transmission.nix:44-47)
14. **✅ ProtectSystem = strict**: Read-only root filesystem with explicit `ReadWritePaths` and `BindPaths` for required directories (transmission.nix:49-67)
15. **✅ Network Restriction**: `RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ]` — raw sockets blocked (transmission.nix:55)
16. **✅ Kernel Hardening**: `RestrictNamespaces`, `LockPersonality`, `ProtectKernelModules`, `ProtectKernelTunables` all set (transmission.nix:57-63)
17. **✅ Custom ExecStartPre**: Replaces upstream `/dev/stdin` usage (unavailable inside confinement's private `/dev`) with a clean shell-redirect approach (transmission.nix:82-98)
18. **✅ Torrent Pruning**: New `transmission-prune-finished-30d` timer and shell script automatically removes finished torrents older than 30 days, with a `DRY_RUN` mode for testing (timers.nix:259-279, bin/transmission-prune-finished-30d.sh)

### ✅ **LUKS & Backup Improvements**

19. **✅ Backup Mount Check**: `backup_nc` now verifies `/home/vlp/backup` is a live mount before rsync runs — prevents silently writing to local storage on unmounted disk (timers.nix:72-77)
20. **✅ luks-sdb1-fixperms Service**: New dedicated service corrects ownership of the backup mount root after it's mounted, so `vlp` can traverse it without the service running as `vlp` (luks-disk.nix:66-86)

### ✅ **Minor Cleanups**

21. **✅ `#weechat` Comment Removed**: The commented-out package in `home.nix` (flagged in February review) is gone
22. **✅ Games Directory**: `/mnt/games` NFS mount and transmission write path added for games category

---

## 🔧 Remaining Improvements

### 🟡 Low Priority

#### 1. **OpenVPN Config Path** 📁
**File:** `configuration.nix` (line 107)

```nix
services.openvpn.servers = {
  officeVPN = { config = '' config /root/fdn.conf ''; };
};
```

**Issue:** `/root/fdn.conf` is not in the Nix store and not version-controlled. The system cannot be fully rebuilt on a new machine without manually copying this file. It's the only remaining reproducibility hole.

**Fix options:**
1. **If the config is not sensitive** — import it into the repo:
   ```nix
   config = builtins.readFile ./vpn/fdn.conf;
   ```
2. **If the config contains secrets** — use agenix:
   ```nix
   config = '' config ${config.age.secrets.openvpn_config.path} '';
   ```

**Priority:** Low — system works fine, but closes the last reproducibility gap.

---

#### 2. **Orphaned Secret File** 🗂️
**File:** `secrets/dl_caddy.age`

This file exists in the `secrets/` directory but is **not referenced** in `secrets/secrets.nix` and **not declared** in `configuration.nix`. It appears to be a leftover from a prior configuration.

**Fix:** Delete it after confirming it's no longer needed:
```bash
git rm secrets/dl_caddy.age
```

**Priority:** Low — it's inert (agenix won't decrypt it), but it's dead weight that could confuse future readers.

---

### 🟢 Very Low Priority (Optional Polish)

#### 3. **`github-runner` Installed But Not Configured** 🏃
**File:** `apps.nix` (line 87)

The `github-runner` package is in `environment.systemPackages` but there's no corresponding `services.github-runner.*` declaration. If the runner is actually being used, it should be managed declaratively:
```nix
services.github-runners.maison = {
  enable = true;
  url = "https://github.com/0x766C70/nixos_maison";
  tokenFile = config.age.secrets.github_runner_token.path;
};
```

If it's not used, remove the package.

**Priority:** Very Low — no operational impact, but it's a loose end.

---

#### 4. **Unused `self` Parameter in home.nix** 🔍
**File:** `home.nix` (line 1)

```nix
{ self, config, pkgs, ... }:
```

`self` is declared in the function signature but never referenced in the file body. Home Manager will pass it, but it's dead weight in the signature.

**Fix:** Remove `self` from the parameter list:
```nix
{ config, pkgs, ... }:
```

**Priority:** Very Low — purely cosmetic, causes no errors.

---

#### 5. **Caddy Virtual Host DRY Optimization** 🔄
**File:** `services/caddy.nix` (lines 59-70)

Four virtual hosts still point to the same backend (`192.168.101.11:80`):
```nix
virtualHosts."web.vlp.fdn.fr".extraConfig = ''reverse_proxy 192.168.101.11:80'';
virtualHosts."farfadet.web.vlp.fdn.fr".extraConfig = ''reverse_proxy 192.168.101.11:80'';
virtualHosts."cv.web.vlp.fdn.fr".extraConfig = ''reverse_proxy 192.168.101.11:80'';
virtualHosts."ai.web.vlp.fdn.fr".extraConfig = ''reverse_proxy 192.168.101.11:80'';
```

**Optional refactor:**
```nix
let
  webServerHosts = [ "web.vlp.fdn.fr" "farfadet.web.vlp.fdn.fr" "cv.web.vlp.fdn.fr" "ai.web.vlp.fdn.fr" ];
in
virtualHosts = lib.genAttrs webServerHosts (_: {
  extraConfig = ''reverse_proxy 192.168.101.11:80'';
});
```

**Priority:** Very Low — current approach is explicit and readable.

---

#### 6. **Add `.gitignore`** 🚫

No `.gitignore` present. Build artifacts like `result` can appear after `nix build`.

**Suggestion:**
```
result
result-*
*.qcow2
.direnv
.envrc
```

**Priority:** Very Low.

---

#### 7. **Code Formatting** 🧹

**Optional tool:** Run `nixfmt` (the new official formatter, replaces `nixpkgs-fmt`) for automated formatting:
```bash
nix run nixpkgs#nixfmt-rfc-style -- .
```

**Note:** Current formatting is already consistent and readable.

---

## ✅ What You're Doing Right

Your configuration exemplifies NixOS best practices at every layer:

### Architecture & Organization
1. ✅ **Flake-based Configuration**: Modern, reproducible, on NixOS 25.11
2. ✅ **Modular Structure**: 12 service modules cleanly separated in `services/`
3. ✅ **Clean Imports**: Well-organized in `configuration.nix`
4. ✅ **Home Manager Integration**: User config properly separated
5. ✅ **Proper File Permissions**: `systemd.tmpfiles.rules` used consistently throughout

### Security
6. ✅ **SSH Keys-Only Auth**: `PasswordAuthentication = false`, YubiKey + ed25519
7. ✅ **Custom SSH Port + AllowUsers**: Reduces automated scanning noise
8. ✅ **fail2ban Brute-Force Protection**: SSH, Caddy basic auth, Nextcloud — all covered
9. ✅ **nftables Firewall**: Explicit port allow-listing with NAT for containers
10. ✅ **Agenix Secrets**: All sensitive data encrypted at rest, owner/mode set per secret
11. ✅ **LUKS Disk Encryption**: Backup disk encrypted, unlocked automatically via agenix key
12. ✅ **Caddy HTTPS**: Automatic TLS for all public virtual hosts
13. ✅ **Basic Auth**: Transmission and laptop access protected via Caddy + agenix hashes
14. ✅ **Root Login Protected**: `PermitRootLogin = "prohibit-password"`
15. ✅ **Transmission Confinement**: Full systemd namespace sandboxing + kernel hardening
16. ✅ **Eval-time Assertions**: Caddy path validation caught before any disk change
17. ✅ **Static Site Security Headers**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` on alicante

### Resilience & Reliability
18. ✅ **NFS Automount**: 9 NFS mounts with `x-systemd.automount` + idle timeout — no boot hangs
19. ✅ **LUKS Graceful Failure**: `nofail` + device existence check — boots without backup disk
20. ✅ **Backup Mount Verification**: `backup_nc` aborts if disk is not actually mounted
21. ✅ **Dual Backup Strategy**: Local (4 AM) + remote via reverse SSH tunnel (5 AM)
22. ✅ **Backup Failure Notifications**: systemd `onFailure` hooks with email alerts
23. ✅ **Timer Error Handling**: `set -e` in all service scripts
24. ✅ **Persistent Timers**: All timers run on boot if missed
25. ✅ **State Management**: `my_ip` tracks last known IP in `/var/lib`
26. ✅ **Torrent Auto-Pruning**: 30-day cleanup prevents download directory sprawl
27. ✅ **LUKS Permission Fix**: Dedicated post-mount service corrects ownership automatically

### Monitoring & Observability
28. ✅ **Prometheus + Node Exporter**: Extended collectors (systemd, ethtool, tcpstat, wifi)
29. ✅ **Grafana Cloud Remote Write**: Metrics shipped off-box
30. ✅ **IP Change Notifications**: Polling every 2 hours with state deduplication
31. ✅ **Structured Logging**: Caddy JSON logs consumed by fail2ban; Nextcloud log_type=file
32. ✅ **Email Alerts**: Backup failures + IP changes trigger immediate notifications

### Services & Features
33. ✅ **Nextcloud 32**: Latest version, PostgreSQL backend, Redis cache, 1 GB upload limit
34. ✅ **Rich App Ecosystem**: news, bookmarks, contacts, calendar, tasks, cookbook, notes, memories, previewgenerator, deck, recognize
35. ✅ **Automated Preview Generation**: Weekly timer for media thumbnails
36. ✅ **Comprehensive Preview Providers**: PDF, Movie, HEIC, Krita, OpenDocument, and more
37. ✅ **Transmission 4 + Flood UI**: Latest daemon with modern web interface
38. ✅ **MiniDLNA + Avahi**: Media streaming to local devices with mDNS discovery
39. ✅ **Tailscale Client**: Mesh VPN access to the tailnet
40. ✅ **Headscale Exposure**: Self-hosted control server accessible via Caddy reverse proxy
41. ✅ **Incus/LXD Containers**: Container management with NAT and trusted bridge interface
42. ✅ **Alicante Static Site**: Compressed, cached, security-header-equipped file server
43. ✅ **Reverse SSH Backup Tunnel**: Clever use of `AllowTcpForwarding` + autossh on remote

### Best Practices
44. ✅ **Static IP Configuration**: Stable network for services
45. ✅ **GPG Agent SSH Support**: YubiKey-backed SSH via `gpg-agent` in both interactive and systemd contexts
46. ✅ **User Linger**: Keeps vlp's systemd session alive for 5 AM backup timer
47. ✅ **Scanner Support**: SANE with Epson backend + `epsonscan2`
48. ✅ **Locale Configuration**: Comprehensive French/US settings
49. ✅ **Automated App Updates**: `autoUpdateApps.enable = true` for Nextcloud

---

## 📈 Configuration Health Metrics

| Category | Score | Status |
|----------|-------|--------|
| **Security** | 10/10 | ✅ Excellent — fail2ban + confinement + agenix + LUKS |
| **Reliability** | 10/10 | ✅ Excellent — comprehensive error handling and notifications |
| **Code Quality** | 9.5/10 | ✅ Excellent — minor cosmetics remain |
| **Documentation** | 9.5/10 | ✅ Excellent — README + inline comments throughout |
| **Maintainability** | 9.5/10 | ✅ Excellent — clean modular structure |
| **Best Practices** | 9.5/10 | ✅ Excellent — follows NixOS standards |
| **Reproducibility** | 9/10 | ✅ Very Good — one hardcoded path remains (OpenVPN) |
| **Overall** | **9.6/10** | ✅ **Production Excellence** |

---

## 🏁 Priority Action Items

### 🟡 Low Priority (When Convenient)

1. ☐ **Move OpenVPN config to Nix store or agenix** (configuration.nix:107)
2. ☐ **Remove orphaned `secrets/dl_caddy.age`** — not referenced anywhere

### 🟢 Very Low Priority (Optional Polish)

3. ☐ Declare `github-runner` as a proper systemd service or remove the package (apps.nix:87)
4. ☐ Remove unused `self` parameter from home.nix function signature
5. ☐ Add `.gitignore` for build artifacts
6. ☐ Consider Caddy DRY optimization for the four web-server virtual hosts (optional)
7. ☐ Run `nixfmt-rfc-style` for automated formatting (optional)

**Bottom Line:** 2 low-priority housekeeping items and 5 purely optional tweaks. The system is production-ready as-is.

---

## 🎬 Final Assessment

The configuration has matured from "excellent" to "excellent *and* battle-hardened." The fail2ban layer, Transmission confinement, and Tailscale integration are meaningful additions that close real attack surfaces and operational gaps. The eval-time assertion in caddy.nix is the kind of defensive Nix-ism that most people only discover after a bad day.

### Trajectory 📊

- **0 Critical Issues**
- **0 High Priority Issues**
- **0 Medium Priority Issues**
- **2 Low Priority Issues** (OpenVPN path + orphaned secret)
- **5 Optional Improvements** (purely cosmetic or alternative approaches)

### What Makes This Configuration Excellent 💎

1. **Truly Reproducible**: Rebuild from scratch on any x86_64 machine (minus the VPN config)
2. **Defense in Depth**: Firewall → fail2ban → basic auth → service confinement — multiple layers
3. **Self-Healing**: Graceful degradation if LUKS disk is absent; abort-on-error backups with notifications
4. **Well-Monitored**: Proactive alerts for failures, IP changes, and backup completions
5. **Maintainable**: 12 focused modules, consistent patterns, inline comments where they matter

### Philosophy Alignment 🎯

- ✅ **Declarative**: Everything defined in code, nothing configured by hand
- ✅ **Reproducible**: One flake, one host definition, fully pinned inputs (99% complete)
- ✅ **Reliable**: Failure paths explicitly handled at every layer
- ✅ **Maintainable**: Well-organized, consistently structured, easy to extend

*"Like a T-800 that also writes clean Nix — relentless, precise, and surprisingly easy to maintain."* 🤖

---

**Review Date:** 2026-04-06  
**Reviewer:** botbot (NixOS Configuration Analyst)  
**Config Version:** NixOS 25.11 (stateVersion: 24.11)  
**Status:** ✅ **Production Ready — Excellence Maintained**
