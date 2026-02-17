#!/usr/bin/env bash
# Maison Homeserver Management Script
# Quick helper for common administrative tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if running as root for some commands
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This command requires root privileges. Please run with sudo."
        exit 1
    fi
}

# Service status check
check_services() {
    print_header "Service Status Check"
    
    # Core services
    services=(
        "caddy"
        "nextcloud-setup"
        "jellyfin"
        "transmission"
        "minidlna"
        "headscale"
        "fail2ban"
        "adguardhome"
        "homepage-dashboard"
        "uptime-kuma"
        "paperless-web"
        "prometheus"
        "smartd"
    )
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            print_success "$service is running"
        else
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                print_error "$service is enabled but not running"
            else
                print_warning "$service is disabled"
            fi
        fi
    done
}

# Backup status
check_backups() {
    print_header "Backup Status"
    
    echo "Recent backup timers:"
    systemctl list-timers backup* --no-pager --no-legend
    
    echo ""
    echo "Last backup runs:"
    journalctl -u backup_nc.service -n 1 --no-pager --output=short-iso || echo "No backup logs found"
    journalctl -u remote_backup_nc.service -n 1 --no-pager --output=short-iso || echo "No remote backup logs found"
}

# Disk health
check_disks() {
    check_root
    print_header "Disk Health Status"
    
    echo "S.M.A.R.T. status for all disks:"
    for disk in /dev/sd?; do
        if [ -e "$disk" ]; then
            echo ""
            echo "=== $disk ==="
            smartctl -H "$disk" 2>/dev/null || echo "S.M.A.R.T. not supported or disk not found"
        fi
    done
}

# fail2ban status
check_fail2ban() {
    check_root
    print_header "fail2ban Status"
    
    echo "SSH bans:"
    fail2ban-client status sshd 2>/dev/null || print_warning "sshd jail not found"
    
    echo ""
    echo "Caddy bans:"
    fail2ban-client status caddy-auth 2>/dev/null || print_warning "caddy-auth jail not found"
}

# System resources
check_resources() {
    print_header "System Resources"
    
    echo "CPU and Memory:"
    top -bn1 | head -n 5
    
    echo ""
    echo "Disk usage:"
    df -h / /root/backup /var/lib/nextcloud/data 2>/dev/null | grep -v tmpfs || true
    
    echo ""
    echo "Top memory consumers:"
    ps aux --sort=-%mem | head -n 6
}

# Quick restart of all services
restart_all() {
    check_root
    print_header "Restarting All Services"
    
    print_warning "This will restart all homeserver services. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    services=(
        "caddy"
        "jellyfin"
        "homepage-dashboard"
        "uptime-kuma"
        "paperless-web"
        "adguardhome"
    )
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "Restarting $service..."
            systemctl restart "$service"
            print_success "$service restarted"
        fi
    done
}

# Show service URLs
show_urls() {
    print_header "Service Access URLs"
    
    cat << 'EOF'
📍 Core Services:
  • Family Portal:  https://home.vlp.fdn.fr
  • Nextcloud:      https://nuage.vlp.fdn.fr
  • Jellyfin:       https://media.vlp.fdn.fr
  • Transmission:   https://dl.vlp.fdn.fr
  • Paperless:      https://docs.vlp.fdn.fr
  • Uptime Kuma:    https://status.vlp.fdn.fr
  • AdGuard Home:   http://192.168.1.42:3000
  • Headscale:      https://hs.vlp.fdn.fr

📍 Optional Services (if enabled):
  • Vaultwarden:    https://vault.vlp.fdn.fr
  • Calibre-web:    https://books.vlp.fdn.fr
  • FreshRSS:       https://rss.vlp.fdn.fr
  • PhotoPrism:     https://photos.vlp.fdn.fr
  • Grafana:        https://grafana.vlp.fdn.fr
EOF
}

# Update system
update_system() {
    check_root
    print_header "System Update"
    
    print_warning "This will update the system. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    echo "Updating flake inputs..."
    nix flake update
    
    echo ""
    echo "Rebuilding system..."
    nixos-rebuild switch --flake .#maison
    
    print_success "System updated successfully!"
}

# Main menu
show_menu() {
    echo ""
    print_header "Maison Homeserver Management"
    echo ""
    echo "Choose an option:"
    echo "  1) Check service status"
    echo "  2) Check backup status"
    echo "  3) Check disk health"
    echo "  4) Check fail2ban bans"
    echo "  5) Check system resources"
    echo "  6) Show service URLs"
    echo "  7) Restart all services"
    echo "  8) Update system"
    echo "  9) Exit"
    echo ""
    read -r -p "Enter choice [1-9]: " choice
    
    case $choice in
        1) check_services ;;
        2) check_backups ;;
        3) check_disks ;;
        4) check_fail2ban ;;
        5) check_resources ;;
        6) show_urls ;;
        7) restart_all ;;
        8) update_system ;;
        9) exit 0 ;;
        *) print_error "Invalid option" ;;
    esac
    
    echo ""
    read -r -p "Press Enter to continue..."
    show_menu
}

# If no arguments, show menu
if [ $# -eq 0 ]; then
    show_menu
else
    # Allow direct command execution
    case $1 in
        status) check_services ;;
        backup) check_backups ;;
        disks) check_disks ;;
        fail2ban) check_fail2ban ;;
        resources) check_resources ;;
        urls) show_urls ;;
        restart) restart_all ;;
        update) update_system ;;
        *)
            echo "Usage: $0 {status|backup|disks|fail2ban|resources|urls|restart|update}"
            echo "Or run without arguments for interactive menu"
            exit 1
            ;;
    esac
fi
