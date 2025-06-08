#!/bin/bash
# Ubuntu Cloud Image Optimization Script - SAFE VERSION (REV 2.0)
# Optimizes Ubuntu 22.04 for Docker while keeping SSH/Network stable
set -e

echo "=== Ubuntu Optimization for Docker (SAFE VERSION v2.0) ==="
echo "Keeps systemd-networkd and systemd-logind for SSH stability"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize variables
NETWORK_OK=false
OPTIMIZATION_SUMMARY=()

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# Show current memory usage
log_info "Current memory usage:"
free -h
echo ""

log_info "Starting safe optimization..."

# 1. Disable unnecessary services (KEEP networkd and logind)
log_info "Disabling unnecessary services..."

disable_service() {
    local service=$1
    local reason=$2
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        systemctl disable "$service" 2>/dev/null && {
            log_info "Disabled $service ($reason)"
            OPTIMIZATION_SUMMARY+=("Disabled service: $service ($reason)")
        } || log_warn "Failed to disable $service"
    fi
}

# Snap services
disable_service snapd "Snap daemon"
disable_service snapd.socket "Snap socket"
systemctl mask snapd 2>/dev/null || log_warn "Failed to mask snapd"

# Ubuntu specific services
disable_service ubuntu-advantage "Ubuntu Advantage"
disable_service ua-reboot-cmds "Ubuntu Advantage reboot"
disable_service pollinate "Entropy service"

# Network services
disable_service networkd-dispatcher "Network dispatcher"
disable_service systemd-networkd-wait-online "Network wait online"
disable_service systemd-resolved "DNS resolver (using static resolv.conf)"

## Ensure resolv.conf exists with valid DNS (critical!)
if lsattr /etc/resolv.conf 2>/dev/null | grep -q '\-i\-'; then
    chattr -i /etc/resolv.conf
    log_info "Removed immutable attribute from existing resolv.conf"
fi
rm -f /etc/resolv.conf
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
chattr +i /etc/resolv.conf

# Storage services
disable_service lvm2-monitor "LVM monitoring"
disable_service blk-availability "Block availability"
disable_service e2scrub_reap "Filesystem scrub"
disable_service open-iscsi "iSCSI initiator"

# Security services
disable_service apparmor "AppArmor (container environment)"
disable_service secureboot-db "SecureBoot DB"

# Boot services
disable_service grub-common "GRUB common"
disable_service grub-initrd-fallback "GRUB fallback"

# Other services
disable_service unattended-upgrades "Auto-updates"
disable_service getty@tty1 "Console getty"

systemctl daemon-reload
log_info "Services disabled successfully (keeping networkd + logind for stability)"

# 2. Remove unnecessary packages
log_info "Removing unnecessary packages..."

remove_package() {
    local package=$1
    local reason=$2
    if dpkg -l | grep -q "^ii  $package "; then
        if apt remove --purge -y "$package" 2>/dev/null; then
            log_info "Removed $package ($reason)"
            OPTIMIZATION_SUMMARY+=("Removed package: $package ($reason)")
        else
            log_warn "Failed to remove $package"
        fi
    else
        log_warn "$package not installed, skipping"
    fi
}

packages_to_remove=(
    "snapd:Snap package manager"
    "lxd-agent-loader:LXD agent"
    "lxd-installer:LXD installer" 
    "ubuntu-advantage-tools:Ubuntu Advantage"
    "pollinate:Entropy service"
    "unattended-upgrades:Auto-updates"
    "networkd-dispatcher:Network dispatcher"
    "open-iscsi:iSCSI initiator"
    "lvm2:LVM tools"
)

for package_info in "${packages_to_remove[@]}"; do
    package=${package_info%%:*}
    reason=${package_info#*:}
    remove_package "$package" "$reason"
done

# 3. Clean up
log_info "Cleaning up..."
apt autoremove --purge -y
apt autoclean

# 4. Configure journald for space optimization
log_info "Configuring systemd journald..."

configure_journald() {
    local config_file="/etc/systemd/journald.conf"
    local tmp_file=$(mktemp)
    
    # Remove existing settings if present
    grep -vE '^(SystemMaxUse|RuntimeMaxUse|# Optimization settings)' "$config_file" > "$tmp_file"
    
    # Add new settings
    echo -e "\n# Optimization settings - Added by optimization script" >> "$tmp_file"
    echo "SystemMaxUse=50M" >> "$tmp_file"
    echo "RuntimeMaxUse=50M" >> "$tmp_file"
    
    # Replace config file
    mv "$tmp_file" "$config_file"
    chmod 644 "$config_file"
    
    systemctl restart systemd-journald
    log_info "Journald configured with size limits"
    OPTIMIZATION_SUMMARY+=("Configured journald: Size limits 50MB")
}

configure_journald

# 5. Test critical services and show REAL status
echo ""
log_info "Testing critical services..."

test_service() {
    local service=$1
    local description=$2
    local status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
    
    if [ "$status" = "active" ]; then
        echo "  ✓ $description: $status"
        return 0
    else
        echo "  ✗ $description: $status"
        return 1
    fi
}

test_service ssh "SSH service"
test_service systemd-networkd "Network service"
test_service systemd-logind "Login manager"
test_service systemd-timesyncd "Time sync"
test_service dbus "D-Bus"

# Test network connectivity
echo ""
log_info "Testing network connectivity..."

test_network() {
    if getent hosts google.com >/dev/null 2>&1; then
        echo "  ✓ Network connectivity: OK"
        NETWORK_OK=true
    elif exec 3<>/dev/tcp/8.8.8.8/53 2>/dev/null; then
        exec 3<&-; exec 3>&-
        echo "  ✓ Network connectivity: OK"
        NETWORK_OK=true
    else
        echo "  ✗ Network connectivity: FAILED"
        NETWORK_OK=false
    fi
}

test_network

# Show optimization results
echo ""
log_info "Current memory usage after optimization:"
free -h

echo ""
log_info "All enabled services:"
systemctl list-unit-files --state=enabled --type=service --no-pager | tail -n +2 | head -n -2

echo ""
log_info "=== OPTIMIZATION SUMMARY ==="
printf '%s\n' "${OPTIMIZATION_SUMMARY[@]}"

echo ""
if systemctl is-active --quiet ssh && [ "$NETWORK_OK" = true ]; then
    log_info "✅ OPTIMIZATION SUCCESSFUL - SSH and network working"
    echo ""
    log_info "Safe to reboot: sudo reboot"
else
    log_error "❌ OPTIMIZATION ISSUES DETECTED"
    echo "Check services above before rebooting!"
    
    # Show additional debug info
    echo ""
    log_warn "Debug information:"
    echo "  SSH status: $(systemctl is-active ssh)"
    echo "  Network interfaces:"
    ip -br addr show | grep -v "DOWN"
fi

echo ""
log_info "Post-reboot verification commands:"
echo "  ps aux --sort=-%mem | head -15    # Check running processes"
echo "  systemctl list-units --failed     # Check failed services"  
echo "  free -h                          # Check RAM usage"
echo "  docker --version                 # Install Docker when ready"
