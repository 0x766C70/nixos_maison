#!/usr/bin/env bash
# fail2ban-manager.sh - Management utility for fail2ban intrusion prevention
# This script provides a friendly interface to monitor and manage fail2ban jails

set -euo pipefail

# Colors for output (because security should look cool)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root (required for fail2ban-client)
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Display fail2ban status
show_status() {
    info "Checking fail2ban service status..."
    echo
    systemctl status fail2ban --no-pager || true
    echo
    
    info "Jail status summary:"
    fail2ban-client status || true
}

# Show detailed status for all jails
show_jails() {
    info "Detailed jail statistics:"
    echo
    
    # Get list of active jails
    local jails=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr ',' '\n' | xargs)
    
    if [ -z "$jails" ]; then
        warning "No active jails found"
        return
    fi
    
    for jail in $jails; do
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo -e "${GREEN}Jail: $jail${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        fail2ban-client status "$jail" || true
        echo
    done
}

# Show currently banned IPs across all jails
show_banned() {
    info "Currently banned IP addresses:"
    echo
    
    local jails=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr ',' '\n' | xargs)
    
    if [ -z "$jails" ]; then
        warning "No active jails found"
        return
    fi
    
    local found_bans=false
    for jail in $jails; do
        local banned=$(fail2ban-client status "$jail" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | xargs)
        if [ -n "$banned" ] && [ "$banned" != "" ]; then
            echo -e "${YELLOW}[$jail]${NC} $banned"
            found_bans=true
        fi
    done
    
    if [ "$found_bans" = false ]; then
        success "No IPs are currently banned (peaceful times!)"
    fi
}

# Unban a specific IP address from all jails
unban_ip() {
    local ip="$1"
    
    if [ -z "$ip" ]; then
        error "Please provide an IP address to unban"
        echo "Usage: $0 unban <IP_ADDRESS>"
        exit 1
    fi
    
    info "Attempting to unban $ip from all jails..."
    
    local jails=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr ',' '\n' | xargs)
    
    if [ -z "$jails" ]; then
        warning "No active jails found"
        return
    fi
    
    local unbanned=false
    for jail in $jails; do
        if fail2ban-client set "$jail" unbanip "$ip" 2>/dev/null; then
            success "Unbanned $ip from jail: $jail"
            unbanned=true
        fi
    done
    
    if [ "$unbanned" = false ]; then
        warning "$ip was not banned in any jail"
    fi
}

# Ban a specific IP address in a jail
ban_ip() {
    local jail="$1"
    local ip="$2"
    
    if [ -z "$jail" ] || [ -z "$ip" ]; then
        error "Please provide both jail name and IP address"
        echo "Usage: $0 ban <JAIL_NAME> <IP_ADDRESS>"
        exit 1
    fi
    
    info "Banning $ip in jail $jail..."
    
    if fail2ban-client set "$jail" banip "$ip"; then
        success "Successfully banned $ip in $jail"
    else
        error "Failed to ban $ip in $jail"
        exit 1
    fi
}

# Show fail2ban logs
show_logs() {
    local lines="${1:-50}"
    
    info "Showing last $lines lines of fail2ban logs:"
    echo
    
    journalctl -u fail2ban -n "$lines" --no-pager || true
}

# Show recent ban activity
show_activity() {
    info "Recent ban activity:"
    echo
    
    journalctl -u fail2ban | grep -E "(Ban|Unban)" | tail -20 || {
        warning "No recent ban activity found"
    }
}

# Reload fail2ban configuration
reload_config() {
    info "Reloading fail2ban configuration..."
    
    if fail2ban-client reload; then
        success "Configuration reloaded successfully"
    else
        error "Failed to reload configuration"
        exit 1
    fi
}

# Display usage information
show_help() {
    cat << EOF
${GREEN}fail2ban-manager.sh${NC} - Fail2ban Management Utility

${YELLOW}Usage:${NC}
    $0 <command> [arguments]

${YELLOW}Commands:${NC}
    status              Show fail2ban service status and jail summary
    jails               Show detailed statistics for all jails
    banned              List all currently banned IP addresses
    unban <IP>          Unban a specific IP address from all jails
    ban <JAIL> <IP>     Ban a specific IP in a jail
    logs [N]            Show last N lines of fail2ban logs (default: 50)
    activity            Show recent ban/unban activity
    reload              Reload fail2ban configuration
    help                Show this help message

${YELLOW}Examples:${NC}
    $0 status                    # Check overall status
    $0 banned                    # See who's in jail
    $0 unban 203.0.113.42        # Give someone a second chance
    $0 ban sshd 203.0.113.99     # Manually ban an IP in SSH jail
    $0 logs 100                  # View last 100 log entries
    $0 activity                  # See recent ban activity

${YELLOW}Available Jails:${NC}
    sshd                SSH protection (port 1337)
    caddy-auth          Caddy basic auth protection
    nextcloud           Nextcloud login protection
    http-auth           Generic HTTP auth protection

${GREEN}Pro Tip:${NC} Run 'watch -n 5 sudo $0 banned' to monitor banned IPs in real-time!
EOF
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        status)
            check_root
            show_status
            ;;
        jails)
            check_root
            show_jails
            ;;
        banned)
            check_root
            show_banned
            ;;
        unban)
            check_root
            unban_ip "${2:-}"
            ;;
        ban)
            check_root
            ban_ip "${2:-}" "${3:-}"
            ;;
        logs)
            check_root
            show_logs "${2:-50}"
            ;;
        activity)
            check_root
            show_activity
            ;;
        reload)
            check_root
            reload_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
