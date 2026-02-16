# Headscale Configuration Guide 🔐

## What is Headscale?

Headscale is an open-source, self-hosted implementation of the Tailscale control server. Think of it as your own private VPN coordinator—like having your own air traffic control tower, except instead of planes, you're managing secure connections between your devices.

## Current Configuration

Your headscale instance is configured at **https://hs.vlp.fdn.fr** and provides:

- **Mesh VPN Network**: Secure peer-to-peer connections between devices
- **MagicDNS**: Automatic DNS resolution for devices on your network
- **Zero Configuration**: Once set up, devices automatically discover each other
- **Standard IP Ranges**: Uses Tailscale-compatible IP ranges for seamless operation

### Service Details

- **Server URL**: `https://hs.vlp.fdn.fr`
- **Local Port**: `8085` (not exposed externally)
- **Reverse Proxy**: Caddy handles HTTPS and external access
- **Database**: SQLite (simple, reliable, no separate DB server needed)
- **IPv4 Range**: `100.64.0.0/10`
- **IPv6 Range**: `fd7a:115c:a1e0::/48`

## Getting Started

### 1. Create a User (or "Namespace")

On the server, create a user/namespace for organizing your devices:

```bash
sudo headscale users create yourname
```

### 2. Connect Your First Device

On any device where you have Tailscale installed:

```bash
# Connect to your headscale server
sudo tailscale up --login-server https://hs.vlp.fdn.fr
```

This will give you a registration URL. Copy it.

### 3. Register the Device

Back on the server, register the device:

```bash
# List pending nodes
sudo headscale nodes list

# Register a node (use the ID from the list)
sudo headscale nodes register --user yourname --key <registration-key>
```

### 4. Verify Connection

On your device:

```bash
# Check status
tailscale status

# Test connectivity to other devices
ping hostname.vlp.fdn.fr
```

## Common Operations

### List All Users

```bash
sudo headscale users list
```

### List All Nodes

```bash
sudo headscale nodes list
```

### Remove a Node

```bash
sudo headscale nodes delete --identifier <node-id>
```

### Generate Pre-Authentication Keys

For easier device registration:

```bash
sudo headscale preauthkeys create --user yourname --expiration 24h
```

Then use it when connecting:

```bash
sudo tailscale up --login-server https://hs.vlp.fdn.fr --authkey <preauth-key>
```

### View Routes

```bash
sudo headscale routes list
```

## Advanced Configuration

### Enable Exit Node

To route all traffic through a specific device:

On the exit node device:
```bash
sudo tailscale up --advertise-exit-node --login-server https://hs.vlp.fdn.fr
```

On the server:
```bash
sudo headscale routes list
sudo headscale routes enable --identifier <route-id>
```

On client devices:
```bash
sudo tailscale up --exit-node=<exit-node-name>
```

### Subnet Routing

To access devices on a specific subnet through a node:

On the subnet router device:
```bash
sudo tailscale up --advertise-routes=192.168.1.0/24 --login-server https://hs.vlp.fdn.fr
```

On the server:
```bash
sudo headscale routes list
sudo headscale routes enable --identifier <route-id>
```

## Troubleshooting

### Check Service Status

```bash
sudo systemctl status headscale
```

### View Logs

```bash
sudo journalctl -u headscale -f
```

### Test Connectivity

```bash
# Test if headscale is responding
curl https://hs.vlp.fdn.fr/health
```

### Common Issues

**"Cannot connect to headscale server"**
- Verify DNS is resolving: `dig hs.vlp.fdn.fr`
- Check firewall: Ports 80 and 443 must be open
- Verify Caddy is running: `sudo systemctl status caddy`

**"Node not registering"**
- Ensure you created a user first: `sudo headscale users create yourname`
- Check for typos in the server URL
- Verify the node is actually running Tailscale

**"MagicDNS not working"**
- Ensure your device accepted the DNS configuration
- On Linux: `resolvectl status` should show 100.100.100.100 as a DNS server
- On macOS/Windows: Check network settings for DNS servers

## Security Considerations

1. **Access Control**: Only devices you explicitly register can join the network
2. **Encryption**: All traffic between nodes is encrypted end-to-end
3. **No Data Storage**: Headscale only coordinates connections; it doesn't see your traffic
4. **Authentication**: Use pre-auth keys with expiration for automated deployments
5. **HTTPS Only**: All control plane communication uses TLS via Caddy

## NixOS Configuration Details

The configuration lives in `/home/runner/work/nixos_maison/nixos_maison/services/headscale.nix` and includes:

- **Service enabled**: `services.headscale.enable = true`
- **Local binding**: Listens only on `127.0.0.1:8085` (not exposed to network)
- **Reverse proxy**: Caddy provides HTTPS termination and external access
- **Database**: SQLite stored in `/var/lib/headscale/db.sqlite`
- **Configuration**: Managed declaratively via NixOS options

### Modifying the Configuration

Edit `services/headscale.nix` and rebuild:

```bash
sudo nixos-rebuild switch --flake .#maison
```

## References

- [Headscale Documentation](https://headscale.net/)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [NixOS Headscale Options](https://mynixos.com/options/services.headscale)

## Need Help?

If things go sideways (and let's be honest, they occasionally do), remember:
- Check the logs first: `sudo journalctl -u headscale -n 100`
- Verify your configuration: `/nix/store/.../bin/headscale config show`
- The headscale community is friendly: https://github.com/juanfont/headscale/discussions

---

*"In the game of VPNs, you either win or you expose your internal network to the internet. Let's make sure we're winning."*
