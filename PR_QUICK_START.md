# 🚀 Quick Start - Using the Split PRs

The monolithic PR has been split into **9 focused PRs**. Here's how to use them.

## ✅ Already Created (Ready to Review)

Three PRs are **already created and committed** in separate branches:

### 1. PR #1: Security Foundation ⭐ START HERE
```bash
git checkout copilot/pr1-security-foundation
```

**What's in it:**
- fail2ban (protects SSH + Caddy from brute-force)
- smartd (disk health monitoring with email alerts)
- auto-upgrade (weekly NixOS security updates)

**Why first:** Essential security hardening, zero risk, immediate benefit.

**Test it:**
```bash
sudo nixos-rebuild dry-build --flake .#maison
```

---

### 2. PR #2: Family Portal & Monitoring
```bash
git checkout copilot/pr2-portal-monitoring
```

**What's in it:**
- Homepage dashboard at https://home.vlp.fdn.fr
- Uptime Kuma monitoring at https://status.vlp.fdn.fr

**Why next:** Quick usability win for the family.

---

### 3. PR #3: Jellyfin Media Server
```bash
git checkout copilot/pr3-jellyfin
```

**What's in it:**
- Jellyfin at https://media.vlp.fdn.fr (port 8096)
- Modern Netflix-like media streaming

**Big win:** Family will love this upgrade from DLNA!

---

## 📋 To Be Created (When Needed)

The remaining 6 PRs have **complete instructions** in `PR_SPLIT_GUIDE.md`.

### Quick Create Examples:

**PR #4 (AdGuard Home):**
```bash
git checkout -b copilot/pr4-adguard 4d66654
# Keep only services/adguard.nix, update config
# See PR_SPLIT_GUIDE.md for details
```

**PR #5 (Paperless):**
```bash
git checkout -b copilot/pr5-paperless 4d66654
# Keep only services/paperless.nix
```

**PRs #6-8 (Optional Services):**
- Vaultwarden (password manager)
- Calibre-web + FreshRSS (content)
- PhotoPrism + Grafana + Restic (advanced)

**PR #9 (Documentation):**
- Management scripts
- Complete guides

---

## 🎯 Recommended Flow

### Option A: Deploy Incrementally (RECOMMENDED)
1. Review & merge PR #1 → Deploy → Test → ✅
2. Review & merge PR #2 → Deploy → Test → ✅
3. Review & merge PR #3 → Deploy → Test → ✅
4. Continue with PRs #4-5 as desired
5. Enable optional services (PRs #6-8) when ready

### Option B: Review All, Deploy Together
1. Review all 3 created PRs
2. Create remaining PRs from instructions
3. Test everything in staging
4. Deploy all at once

### Option C: Cherry-Pick What You Want
- Just want security? → Merge PR #1
- Just want media? → Merge PR #3
- Skip optional services entirely

---

## 🔍 How to Review a PR

```bash
# Checkout the PR branch
git checkout copilot/pr1-security-foundation

# See what changed
git diff 4d66654..HEAD

# See which files changed
git diff --name-only 4d66654..HEAD

# Test build (no changes)
sudo nixos-rebuild dry-build --flake .#maison

# Deploy (if in staging)
sudo nixos-rebuild switch --flake .#maison

# Verify services started
systemctl status fail2ban
systemctl status smartd
```

---

## 📊 Quick Comparison

| PR | Services | Priority | Risk | Effort |
|----|----------|----------|------|--------|
| #1 | Security | ⭐⭐⭐ | Very Low | 5 min |
| #2 | Portal | ⭐⭐ | Very Low | 5 min |
| #3 | Jellyfin | ⭐⭐ | Low | 10 min |
| #4 | AdGuard | ⭐ | Medium | 15 min |
| #5 | Paperless | ⭐ | Low | 10 min |
| #6-8 | Optional | Optional | Very Low | Variable |
| #9 | Docs | Helpful | None | 5 min |

---

## �� Pro Tips

1. **Start with PR #1** - It's the safest and most valuable
2. **Test in dry-build first** - Always check before deploying
3. **One PR at a time** - Don't rush, test each one
4. **Optional PRs are optional** - Merge them only when needed
5. **PR #9 helps** - Docs make everything easier

---

## 🆘 Help!

### "I want to start fresh"
The original monolithic PR is still in branch `copilot/improve-nixos-home-server`

### "I just want security improvements"
```bash
git checkout copilot/pr1-security-foundation
sudo nixos-rebuild switch --flake .#maison
```

### "I want everything"
Review and merge PRs #1-5, then enable optional ones as needed.

### "Where are the instructions?"
Complete details in `PR_SPLIT_GUIDE.md`

---

## ✨ The Point

Instead of reviewing **14 services in one giant PR**, you now have:
- ✅ 3 ready-to-review focused PRs
- ✅ 6 more with complete instructions
- ✅ Each PR is independent and safe
- ✅ Deploy what you want, skip what you don't

**Start with PR #1 (Security) and go from there!** 🚀
