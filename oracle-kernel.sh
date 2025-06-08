#!/bin/bash

# Oracle Kernel Auto-Update Script for Ubuntu on Oracle Cloud
# Version: 1.0
# Author: Auto-generated script
# Description: Automatically checks and updates Oracle-optimized kernel to latest version

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if running on Oracle Cloud
check_oracle_cloud() {
    if [[ ! -f /sys/class/dmi/id/sys_vendor ]] || ! grep -qi "oracle" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
        log_warning "This script is designed for Oracle Cloud Infrastructure"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Get current kernel version
get_current_kernel() {
    CURRENT_KERNEL=$(uname -r)
    log "Current kernel: $CURRENT_KERNEL"
}

# Update package lists
update_packages() {
    log "Updating package lists..."
    apt update -qq
    log_success "Package lists updated"
}

# Check for Oracle kernel updates
check_oracle_kernel_updates() {
    log "Checking for Oracle kernel updates..."
    
    # Get current installed version
    CURRENT_ORACLE_VERSION=$(dpkg -l | grep linux-image-oracle | awk '{print $3}' | head -1)
    
    # Get available version
    AVAILABLE_ORACLE_VERSION=$(apt list linux-image-oracle 2>/dev/null | grep -v WARNING | tail -1 | awk '{print $2}')
    
    log "Current Oracle kernel package: $CURRENT_ORACLE_VERSION"
    log "Available Oracle kernel package: $AVAILABLE_ORACLE_VERSION"
    
    if [[ "$CURRENT_ORACLE_VERSION" == "$AVAILABLE_ORACLE_VERSION" ]]; then
        log_success "Oracle kernel is already up to date!"
        return 1
    else
        log_warning "Oracle kernel update available: $CURRENT_ORACLE_VERSION → $AVAILABLE_ORACLE_VERSION"
        return 0
    fi
}

# Check for generic kernel updates (alternative)
check_generic_kernel_updates() {
    log "Checking for generic kernel updates as alternative..."
    
    # Get available generic version
    AVAILABLE_GENERIC_VERSION=$(apt list linux-image-generic 2>/dev/null | grep -v WARNING | tail -1 | awk '{print $2}')
    
    log "Available generic kernel package: $AVAILABLE_GENERIC_VERSION"
    
    # Compare version numbers (basic comparison)
    if dpkg --compare-versions "$AVAILABLE_GENERIC_VERSION" gt "$CURRENT_ORACLE_VERSION" 2>/dev/null; then
        log_warning "Newer generic kernel available: $AVAILABLE_GENERIC_VERSION"
        return 0
    else
        log "Generic kernel is not newer than current Oracle kernel"
        return 1
    fi
}

# Backup current kernel info
backup_kernel_info() {
    log "Creating kernel backup information..."
    
    BACKUP_DIR="/root/kernel_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Save current kernel info
    uname -a > "$BACKUP_DIR/current_kernel.txt"
    dpkg -l | grep linux-image > "$BACKUP_DIR/installed_kernels.txt"
    cp /boot/grub/grub.cfg "$BACKUP_DIR/grub.cfg.backup" 2>/dev/null || true
    
    log_success "Backup created in: $BACKUP_DIR"
    echo "$BACKUP_DIR"
}

# Install Oracle kernel update
install_oracle_kernel() {
    log "Installing Oracle kernel update..."
    
    # Install Oracle kernel and headers
    apt install -y linux-image-oracle linux-headers-oracle
    
    log_success "Oracle kernel installed successfully"
}

# Install generic kernel (if preferred)
install_generic_kernel() {
    log "Installing generic kernel..."
    
    # Install generic kernel and headers
    apt install -y linux-image-generic linux-headers-generic
    
    log_success "Generic kernel installed successfully"
}

# Update GRUB configuration
update_grub_config() {
    log "Updating GRUB configuration..."
    
    update-grub
    
    log_success "GRUB configuration updated"
}

# Clean up old kernels (optional)
cleanup_old_kernels() {
    log "Cleaning up old kernel packages..."
    
    # Remove old kernel packages but keep current and one previous
    apt autoremove --purge -y
    
    log_success "Old kernel packages cleaned up"
}

# Show installed kernels
show_installed_kernels() {
    log "Installed kernel packages:"
    dpkg -l | grep linux-image | grep -v deinstall
}

# Main function
main() {
    echo "=========================================="
    echo "  Oracle Kernel Auto-Update Script"
    echo "=========================================="
    echo
    
    # Pre-flight checks
    check_root
    check_oracle_cloud
    get_current_kernel
    
    # Update package lists
    update_packages
    
    # Check for updates
    if check_oracle_kernel_updates; then
        log_warning "Oracle kernel update found!"
        
        # Ask for confirmation
        read -p "Do you want to install the Oracle kernel update? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_DIR=$(backup_kernel_info)
            install_oracle_kernel
            update_grub_config
            
            log_success "Oracle kernel update completed!"
            log_warning "Reboot required to use new kernel"
            
            read -p "Reboot now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Rebooting system..."
                reboot
            fi
        fi
    elif check_generic_kernel_updates; then
        log_warning "No Oracle kernel update, but newer generic kernel available!"
        
        read -p "Install generic kernel instead? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_DIR=$(backup_kernel_info)
            install_generic_kernel
            update_grub_config
            
            log_success "Generic kernel installed!"
            log_warning "Reboot required. You can choose kernel in GRUB menu"
            
            read -p "Reboot now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Rebooting system..."
                reboot
            fi
        fi
    else
        log_success "No kernel updates available"
    fi
    
    # Show current status
    echo
    show_installed_kernels
    
    # Optional cleanup
    echo
    read -p "Clean up old kernel packages? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_old_kernels
    fi
    
    log_success "Script completed successfully!"
}

# Handle script interruption
trap 'log_error "Script interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
