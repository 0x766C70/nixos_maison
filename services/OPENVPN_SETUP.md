# OpenVPN Configuration Setup

## Overview
The OpenVPN service is now configured in `services/openvpn.nix`. The password/authentication credentials are encrypted using agenix.

## Setup Instructions

### 1. Prepare Your OpenVPN Credentials File

The OpenVPN password file should contain your username and password in the format:
```
username
password
```

Create this file temporarily:
```bash
echo "your_username" > /tmp/openvpn_creds.txt
echo "your_password" >> /tmp/openvpn_creds.txt
```

### 2. Encrypt the Credentials with agenix

```bash
# Navigate to the repository root
cd /home/runner/work/nixos_maison/nixos_maison

# Encrypt the credentials file
agenix -e secrets/openvpn.age
```

This will open your editor. Paste the contents of your credentials file, save, and exit.

### 3. Update the OpenVPN Configuration

Edit `services/openvpn.nix` and replace the placeholder configuration with your actual OpenVPN settings from `/root/fdn.conf`.

Key things to update:
- `remote YOUR_VPN_SERVER_HERE 1194` - Replace with your VPN server address
- TLS/SSL certificate paths - Update or remove if using inline certificates
- Other OpenVPN-specific settings based on your provider

### 4. Clean Up

```bash
# Remove the temporary credentials file
rm -f /tmp/openvpn_creds.txt
```

### 5. Test the Configuration

```bash
# Dry build to check for syntax errors
sudo nixos-rebuild dry-build --flake .#maison

# If successful, apply the configuration
sudo nixos-rebuild switch --flake .#maison
```

### 6. Verify OpenVPN Service

```bash
# Check service status
sudo systemctl status openvpn-officeVPN.service

# View logs
sudo journalctl -u openvpn-officeVPN.service -f
```

## Security Notes

- The `openvpn.age` file contains your encrypted credentials
- Only users with the private keys defined in `secrets/secrets.nix` can decrypt it
- The decrypted file is only accessible by root (mode 0400)
- Never commit unencrypted credentials to the repository

## Troubleshooting

If the VPN connection fails:
1. Check the service logs: `sudo journalctl -u openvpn-officeVPN.service`
2. Verify the credentials are correct in the encrypted file
3. Ensure the OpenVPN server address and settings match your provider's requirements
4. Test the configuration file independently: `sudo openvpn --config /path/to/test.conf`
