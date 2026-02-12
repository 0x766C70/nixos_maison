# LUKS Encrypted Disk Auto-Mount Setup

This configuration automatically unlocks and mounts a LUKS encrypted disk at startup.

## Overview

- **Device**: `/dev/sdb1` (LUKS encrypted partition)
- **Mapper name**: `luks-sdb1`
- **Mount point**: `/mnt/encrypted`
- **Password storage**: Agenix encrypted secret (`secrets/luks_sdb1.age`)
- **Boot behavior**: Non-blocking (boot continues even if disk is unavailable)

## Features

✅ **Automatic unlock at boot** - The disk is automatically unlocked using the password from agenix  
✅ **Non-blocking boot** - If the disk is missing or has errors, boot continues normally  
✅ **Secure password storage** - LUKS password is encrypted with agenix  
✅ **Error handling** - Clear error messages in systemd journal  

## How It Works

1. **systemd service** (`luks-sdb1-unlock.service`) runs at boot after `local-fs.target`
2. Service checks if `/dev/sdb1` exists
3. If device exists, attempts to unlock with password from agenix secret
4. If unlock fails or device is missing, service exits successfully (exit 0)
5. Boot continues regardless of outcome
6. If unlocked successfully, `/dev/mapper/luks-sdb1` is mounted to `/mnt/encrypted`
7. Mount uses `nofail` option to prevent boot hangs

## Setup Instructions

### 1. Prepare Your LUKS Encrypted Disk

If you haven't encrypted `/dev/sdb1` yet:

```bash
# Create LUKS encrypted partition
sudo cryptsetup luksFormat /dev/sdb1

# Open it to format
sudo cryptsetup luksOpen /dev/sdb1 luks-sdb1

# Format with ext4 (or your preferred filesystem)
sudo mkfs.ext4 /dev/mapper/luks-sdb1

# Close it
sudo cryptsetup luksClose luks-sdb1
```

### 2. Create the Encrypted Secret

The LUKS password must be stored in `secrets/luks_sdb1.age`. Replace the placeholder file:

```bash
# Navigate to secrets directory
cd secrets

# Create/edit the secret using agenix
agenix -e luks_sdb1.age
# Enter your LUKS password, save and exit
```

**Alternative method** using age directly:

```bash
# Create a temporary file with your password
echo -n "your-luks-password" > /tmp/luks_password.txt

# Encrypt it with your configured public keys (see secrets/secrets.nix for actual keys)
age -r "ssh-ed25519 AAAA...XXXX root@maison" \
    -r "ssh-ed25519 AAAA...YYYY vlp@maison" \
    -o secrets/luks_sdb1.age < /tmp/luks_password.txt

# Securely delete the temporary file
shred -u /tmp/luks_password.txt
```

**Important**: The password should NOT have a trailing newline. Use `echo -n` to prevent this.

### 3. Apply the Configuration

```bash
# Test the configuration
sudo nixos-rebuild dry-build --flake .#maison

# If successful, apply it
sudo nixos-rebuild switch --flake .#maison
```

### 4. Verify

After reboot, check the service status:

```bash
# Check service status
sudo systemctl status luks-sdb1-unlock.service

# Check if device was unlocked
ls -l /dev/mapper/luks-sdb1

# Check if mounted
mount | grep /mnt/encrypted

# View service logs
sudo journalctl -u luks-sdb1-unlock.service
```

## Configuration Details

### Service Module: `services/luks-disk.nix`

The service follows these principles:

- **Error handling**: Uses explicit error handling with `|| { ... }` blocks to catch failures gracefully
- **Non-blocking**: Always exits with 0 to prevent boot failures
- **Logging**: All actions logged to systemd journal
- **Idempotent**: Can be run multiple times safely

### Secrets Configuration

In `configuration.nix`:
```nix
age.secrets.luks_sdb1 = {
  file = ./secrets/luks_sdb1.age;
  owner = "root";
  group = "root";
  mode = "0400";  # Read-only for root
};
```

In `secrets/secrets.nix`:
```nix
"luks_sdb1.age".publicKeys = [ user1 user2 ];
```

## Troubleshooting

### Device not found at boot

This is expected behavior if the disk is not connected. Check logs:
```bash
sudo journalctl -u luks-sdb1-unlock.service -b
```

You should see: `Device /dev/sdb1 not found, skipping LUKS unlock`

### Wrong password

If the password is incorrect, the service will fail but boot continues. Check logs:
```bash
sudo journalctl -u luks-sdb1-unlock.service -b
```

You should see: `Failed to unlock LUKS device, boot will continue without it`

To fix:
1. Update the password in `secrets/luks_sdb1.age`
2. Run: `sudo systemctl start luks-sdb1-unlock.service`
3. If successful, reboot to test automatic unlock

### Mount point permissions

The mount point `/mnt/encrypted` is created with:
- Owner: `vlp`
- Group: `vlp`
- Permissions: `0750`

To change this, edit `services/luks-disk.nix`:
```nix
systemd.tmpfiles.rules = [
  "d /mnt/encrypted 0750 vlp vlp - -"  # Modify as needed
];
```

## Security Notes

- The LUKS password is stored encrypted with agenix
- Only root can read the decrypted password (mode 0400)
- The password is only decrypted at boot by the agenix agent
- The decrypted password file is stored in `/run/agenix/` (tmpfs)
- Password is never written to disk in plaintext

## Customization

### Change the device

Edit `services/luks-disk.nix` and replace `/dev/sdb1` with your device.

### Change the mount point

Edit `services/luks-disk.nix`:
1. Update the tmpfiles rule to create your desired directory
2. Update the `fileSystems` entry to use your mount point

### Change the filesystem type

Edit `services/luks-disk.nix` and change `fsType = "ext4"` to your filesystem type (e.g., "btrfs", "xfs").

### Make boot blocking (not recommended)

If you want the boot to fail if the disk is not available, remove the `nofail` option from `fileSystems` and change the service to exit with error codes instead of 0.

**Warning**: This can cause boot failures if the disk is disconnected.

## Related Files

- `services/luks-disk.nix` - Main service configuration
- `configuration.nix` - Imports the service and configures the agenix secret
- `secrets/secrets.nix` - Defines the secret encryption keys
- `secrets/luks_sdb1.age` - Encrypted LUKS password (must be created)
