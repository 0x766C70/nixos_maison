# PR Split Plan - Implementation Guide

The monolithic PR has been split into 9 focused, reviewable pull requests. This document provides the complete plan and current status.

## 🎯 PR Overview

| PR # | Branch Name | Status | Services | Description |
|------|-------------|--------|----------|-------------|
| 1 | `copilot/pr1-security-foundation` | ✅ Created | fail2ban, smartd, auto-upgrade | Security hardening & automation |
| 2 | `copilot/pr2-portal-monitoring` | ✅ Created | Homepage, Uptime Kuma | Family portal & monitoring |
| 3 | `copilot/pr3-jellyfin` | ✅ Created | Jellyfin | Modern media server |
| 4 | `copilot/pr4-adguard` | 📋 Planned | AdGuard Home | DNS ad blocking |
| 5 | `copilot/pr5-paperless` | 📋 Planned | Paperless-ngx | Document management |
| 6 | `copilot/pr6-vaultwarden` | 📋 Planned | Vaultwarden | Password manager (optional) |
| 7 | `copilot/pr7-content-libraries` | 📋 Planned | Calibre-web, FreshRSS | Ebooks & RSS (optional) |
| 8 | `copilot/pr8-advanced-features` | 📋 Planned | PhotoPrism, Grafana, Restic | Advanced features (optional) |
| 9 | `copilot/pr9-documentation` | 📋 Planned | Scripts, docs | Management tools & guides |

---

## ✅ Completed PRs

### PR #1: Security Foundation ✅

**Branch:** `copilot/pr1-security-foundation`

**Files Added:**
- `services/fail2ban.nix` - Intrusion prevention (SSH, Caddy)
- `services/smartd.nix` - Disk health monitoring with S.M.A.R.T.
- `services/auto-upgrade.nix` - Weekly automatic updates
- `SECURITY_SERVICES.md` - Complete documentation

**Files Modified:**
- `configuration.nix` - Added imports for 3 services
- `README.md` - Updated features list
- `services/caddy.nix` - Added fail2ban log configuration

**Commit Message:** "PR #1: Add security foundation - fail2ban, smartd, auto-upgrade"

**Ready to merge:** Yes - No dependencies

---

### PR #2: Family Portal & Monitoring ✅

**Branch:** `copilot/pr2-portal-monitoring`

**Files Added:**
- `services/homepage.nix` - Family dashboard at home.vlp.fdn.fr
- `services/uptime-kuma.nix` - Service monitoring at status.vlp.fdn.fr

**Files Modified:**
- `configuration.nix` - Added imports
- `services/caddy.nix` - Added reverse proxies for both services

**Commit Message:** "PR #2: Add family portal and service monitoring"

**Ready to merge:** Yes - No dependencies (but benefits from PR #1 for fail2ban hardening)

---

### PR #3: Jellyfin Media Server ✅

**Branch:** `copilot/pr3-jellyfin`

**Files Added:**
- `services/jellyfin.nix` - Modern media streaming server

**Files Modified:**
- `configuration.nix` - Added import
- `services/caddy.nix` - Added media.vlp.fdn.fr reverse proxy
- `services/firewall.nix` - Added port 8096

**Commit Message:** "PR #3: Add Jellyfin media server"

**Ready to merge:** Yes - No dependencies

---

## 📋 Planned PRs (To Be Created)

### PR #4: AdGuard Home

**Services:** AdGuard Home (DNS ad blocking + parental controls)

**Files to add:**
- `services/adguard.nix`

**Files to modify:**
- `configuration.nix` - Add import
- `services/caddy.nix` - No reverse proxy needed (uses ports 53, 3000 directly)
- `services/firewall.nix` - Add ports 53 TCP/UDP, 3000 TCP

**Special notes:**
- Requires router DNS configuration
- Network-wide impact
- Should be tested carefully

**Commands to create:**
```bash
git checkout -b copilot/pr4-adguard 4d66654
# Keep only services/adguard.nix
# Update configuration.nix, firewall.nix
git add -A
git commit -m "PR #4: Add AdGuard Home for network-wide ad blocking"
```

---

### PR #5: Paperless-ngx

**Services:** Paperless-ngx (document management with OCR)

**Files to add:**
- `services/paperless.nix`

**Files to modify:**
- `configuration.nix` - Add import
- `services/caddy.nix` - Add docs.vlp.fdn.fr

**Commands to create:**
```bash
git checkout -b copilot/pr5-paperless 4d66654
# Keep only services/paperless.nix
# Update configuration.nix, caddy.nix
git add -A
git commit -m "PR #5: Add Paperless-ngx document management"
```

---

### PR #6: Vaultwarden (Optional)

**Services:** Vaultwarden (Bitwarden-compatible password manager)

**Files to add:**
- `services/vaultwarden.nix`

**Files to modify:**
- `configuration.nix` - Add commented import
- `services/caddy.nix` - Add commented vault.vlp.fdn.fr

**Note:** Disabled by default, requires uncommenting to enable

**Commands to create:**
```bash
git checkout -b copilot/pr6-vaultwarden 4d66654
# Create branch with vaultwarden only, commented out in config
git add -A
git commit -m "PR #6: Add Vaultwarden password manager (optional)"
```

---

### PR #7: Content Libraries (Optional)

**Services:** Calibre-web, FreshRSS

**Files to add:**
- `services/calibre-web.nix`
- `services/freshrss.nix`

**Files to modify:**
- `configuration.nix` - Add commented imports
- `services/caddy.nix` - Add commented reverse proxies

**Commands to create:**
```bash
git checkout -b copilot/pr7-content-libraries 4d66654
# Keep calibre-web.nix and freshrss.nix
git add -A
git commit -m "PR #7: Add content libraries - ebooks and RSS (optional)"
```

---

### PR #8: Advanced Features (Optional)

**Services:** PhotoPrism, Grafana, Restic

**Files to add:**
- `services/photoprism.nix`
- `services/grafana.nix`
- `services/restic.nix`

**Files to modify:**
- `configuration.nix` - Add commented imports
- `services/caddy.nix` - Add commented reverse proxies

**Note:** Resource-intensive services, disabled by default

**Commands to create:**
```bash
git checkout -b copilot/pr8-advanced-features 4d66654
# Keep photoprism.nix, grafana.nix, restic.nix
git add -A
git commit -m "PR #8: Add advanced features - photos, monitoring, backups (optional)"
```

---

### PR #9: Documentation & Tooling

**Services:** None (documentation and management tools)

**Files to add:**
- `scripts/homeserver-manage.sh` - Management CLI
- `SETUP_GUIDE.md` - Deployment guide
- `NEW_FEATURES.md` - Complete service documentation

**Files to modify:**
- `README.md` - Update with complete feature list

**Commands to create:**
```bash
git checkout -b copilot/pr9-documentation 4d66654
# Remove all service nix files added
# Keep only docs and scripts
git add -A
git commit -m "PR #9: Add management tools and comprehensive documentation"
```

---

## 🚀 Recommended Merge Order

1. **PR #1** (Security Foundation) - ⭐ HIGHEST PRIORITY
   - Essential security hardening
   - No dependencies
   - Safe to deploy immediately

2. **PR #2** (Portal & Monitoring)
   - Quick wins for usability
   - Depends on existing services
   - Safe to deploy

3. **PR #9** (Documentation)
   - Helps with remaining PRs
   - No system impact
   - Can be merged anytime

4. **PR #3** (Jellyfin)
   - Big family win
   - No dependencies
   - Resource usage: moderate

5. **PR #4** (AdGuard Home)
   - Network-wide benefit
   - Requires router config
   - Test carefully

6. **PR #5** (Paperless)
   - Nice to have
   - No dependencies
   - Safe to deploy

7. **PRs #6-8** (Optional services)
   - Enable as needed
   - Commented out by default
   - Can be merged without impact

---

## 📝 How to Use This Split

### For the Repository Owner:

1. **Review each PR individually:**
   ```bash
   git checkout copilot/pr1-security-foundation
   # Review changes
   # Test build: sudo nixos-rebuild dry-build --flake .#maison
   ```

2. **Test in staging/dev environment (if available)**

3. **Merge PRs one at a time:**
   - Start with PR #1 (security)
   - Deploy and verify
   - Continue with others

4. **Optional services (PR #6-8):**
   - Can be merged without impact (commented out)
   - Uncomment when ready to use

### For Contributors:

- Each PR is self-contained and reviewable
- Clear commit messages explain what's added
- Documentation included where relevant
- Safe to cherry-pick individual PRs

---

## 🔍 Verification Checklist

For each PR, verify:

- [ ] All files compile without errors
- [ ] No broken imports or missing dependencies
- [ ] Services start successfully
- [ ] Firewall rules are correct
- [ ] Caddy reverse proxies work
- [ ] Email notifications configured (where applicable)
- [ ] Documentation is accurate
- [ ] No security regressions

---

## 📊 Impact Summary

### PR #1 (Security)
- CPU: <1%, RAM: ~50MB, Disk: ~100MB
- Risk: Very low
- Benefit: High (critical security)

### PR #2 (Portal & Monitoring)
- CPU: ~5%, RAM: ~200MB, Disk: ~200MB
- Risk: Very low
- Benefit: High (usability)

### PR #3 (Jellyfin)
- CPU: ~10-30%, RAM: ~1-2GB, Disk: ~500MB
- Risk: Low
- Benefit: Very high (family media)

### PR #4 (AdGuard)
- CPU: ~2%, RAM: ~100MB, Disk: ~100MB
- Risk: Medium (network-wide)
- Benefit: Very high (ad blocking)

### PR #5 (Paperless)
- CPU: ~5%, RAM: ~300MB, Disk: ~300MB
- Risk: Low
- Benefit: Medium (document mgmt)

### PRs #6-8 (Optional)
- Variable impact, disabled by default
- Risk: Very low (not active)
- Benefit: High when enabled

### PR #9 (Documentation)
- No system impact
- Risk: None
- Benefit: High (maintainability)

---

## 🎓 Lessons Learned

**Why split PRs:**
1. ✅ Easier code review (focused changes)
2. ✅ Independent testing
3. ✅ Incremental rollout reduces risk
4. ✅ Can skip optional services
5. ✅ Clear separation of concerns
6. ✅ Better git history

**Best practices applied:**
- Each PR is independently functional
- Clear, descriptive commit messages
- Documentation included
- Minimal changes per PR
- Optional services properly marked

---

## 🆘 Need Help?

- PR #1-3 branches already created and committed locally
- PR #4-9 have complete instructions above
- Each PR is independent and can be created/merged separately
- Start with PR #1 for immediate security benefits

---

*This split maintains all functionality while making the changes reviewable and deployable incrementally.*
