#!/bin/bash
# Tên tập tin: xanmod-installer.sh
# Phiên bản: 1.0
# Mô tả: Công cụ cài đặt và quản lý kernel XanMod cho hệ điều hành Debian/Ubuntu
# Tác giả: bibica
#
# Hướng dẫn cài đặt nhanh:
# wget -qO xanmod-installer.sh https://go.bibica.net/xanmod && bash xanmod-installer.sh
#
# Trang dự án: https://github.com/bibicadotnet/ubuntu-22-04-docker

set -e  # Exit on any error

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    echo -e "${BLUE}● $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_header() {
    echo -e "${MAGENTA}$1${NC}"
}

# Check system requirements
check_system() {
    print_msg "Kiểm tra quyền và hệ thống..."
    
    if [ "$(id -u)" -ne 0 ]; then
        print_error "Script cần chạy với sudo!"
        exit 1
    fi

    if [ "$(uname -m)" != "x86_64" ]; then
        print_error "Chỉ hỗ trợ kiến trúc AMD64/x86_64!"
        exit 1
    fi

    if ! command -v dpkg &> /dev/null; then
        print_error "Script này chỉ hỗ trợ hệ thống Debian/Ubuntu!"
        exit 1
    fi

    print_success "Hệ thống hợp lệ"
}

# Detect CPU level
detect_cpu_level() {
    print_msg "Kiểm tra khả năng CPU..."
    cpu_level=$(curl -sSL https://dl.xanmod.org/check_x86-64_psabi.sh | awk -f - | grep -oP 'x86-64-v[0-9]' || echo "x86-64-v1")
    print_success "CPU hỗ trợ: $cpu_level"
    version_suffix="x64$(echo $cpu_level | cut -d'-' -f3)"
}

# Get available versions
get_versions() {
    local branch=$1
    
    local url="https://sourceforge.net/projects/xanmod/files/releases/$branch/"
    local versions=$(curl -sSL "$url" | grep -oP 'title="\K[0-9.]+-xanmod[0-9]+' | head -n10)
    
    if [ -z "$versions" ]; then
        return 1
    fi
    
    echo "$versions"
}

# Remove all XanMod kernels
remove_xanmod_kernels() {
    local force_mode=$1  # true for automatic removal, false for manual confirmation
    
    print_msg "Tìm và xóa tất cả kernel XanMod hiện có..."
    
    local xanmod_packages=$(dpkg -l | grep -E 'linux-(image|headers).*xanmod' | awk '{print $2}' | sort)
    
    if [ -z "$xanmod_packages" ]; then
        print_info "Không tìm thấy kernel XanMod nào để xóa"
        return 0
    fi
    
    print_warning "Tìm thấy các kernel XanMod sau:"
    echo "$xanmod_packages" | while read pkg; do
        echo "  - $pkg"
    done
    
    echo ""
    
    print_msg "Đang xóa kernel XanMod..."
    echo "$xanmod_packages" | xargs apt-get remove --purge -y
    
    print_msg "Cập nhật GRUB..."
    update-grub
    
    print_success "Đã xóa tất cả kernel XanMod"
    return 0
}

# Install specific XanMod version
install_xanmod() {
    local branch=$1
    local selected_version=$2
    
    # Remove existing XanMod kernels first (automatic mode)
    if dpkg -l | grep -q 'linux.*xanmod'; then
        print_warning "Phát hiện kernel XanMod đã cài đặt"
        remove_xanmod_kernels "true" || return 1
    fi
    
    print_msg "Bắt đầu cài đặt XanMod $selected_version..."
    
    # Create temp directory
    local temp_dir="/tmp/xanmod_install_$$"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    print_success "Tạo thư mục tạm: $temp_dir"
    
    # Build package info
    local base_version="${selected_version%-xanmod*}"
    local package_dir="${selected_version}/${base_version}-${version_suffix}-xanmod1"
    local base_url="https://sourceforge.net/projects/xanmod/files/releases/$branch/${package_dir}"
    
    print_msg "Lấy thông tin package từ SourceForge..."
    local page_content=$(curl -sSL "$base_url/" | tr -d '\n' | tr -d '\r')
    
    # Extract file names
    local headers_file=$(echo "$page_content" | grep -oP 'title="linux-headers-[^"]*\.deb"' | sed 's/title="//g' | sed 's/"//g' | head -n1)
    local image_file=$(echo "$page_content" | grep -oP 'title="linux-image-[^"]*\.deb"' | sed 's/title="//g' | sed 's/"//g' | head -n1)
    
    # Alternative extraction method
    if [ -z "$headers_file" ] || [ -z "$image_file" ]; then
        print_warning "Thử phương pháp khác để lấy tên file..."
        headers_file=$(echo "$page_content" | grep -oP 'href="[^"]*linux-headers-[^"]*\.deb[^"]*"' | sed 's/href="//g' | sed 's/".*//g' | head -n1 | xargs basename)
        image_file=$(echo "$page_content" | grep -oP 'href="[^"]*linux-image-[^"]*\.deb[^"]*"' | sed 's/href="//g' | sed 's/".*//g' | head -n1 | xargs basename)
    fi
    
    # Manual construction if needed
    if [ -z "$headers_file" ] || [ -z "$image_file" ]; then
        print_warning "Tạo tên file thủ công..."
        local timestamp=$(echo "$page_content" | grep -oP '~[0-9]{8}\.g[a-f0-9]+' | head -n1)
        if [ -z "$timestamp" ]; then
            timestamp="~$(date +%Y%m%d).g$(openssl rand -hex 3)"
        fi
        
        headers_file="linux-headers-${base_version}-${version_suffix}-xanmod1_${base_version}-${version_suffix}-xanmod1-0${timestamp}_amd64.deb"
        image_file="linux-image-${base_version}-${version_suffix}-xanmod1_${base_version}-${version_suffix}-xanmod1-0${timestamp}_amd64.deb"
    fi
    
    if [ -z "$headers_file" ] || [ -z "$image_file" ]; then
        print_error "Không thể xác định tên file!"
        cd / && rm -rf "$temp_dir"
        return 1
    fi
    
    print_success "File headers: $headers_file"
    print_success "File image: $image_file"
    
    # Download files
    local headers_url="${base_url}/${headers_file}/download"
    local image_url="${base_url}/${image_file}/download"
    
    print_msg "Đang tải xuống kernel packages..."
    
    if ! wget -q --show-progress -O "$headers_file" "$headers_url"; then
        print_error "Lỗi khi tải headers"
        cd / && rm -rf "$temp_dir"
        return 1
    fi
    
    if ! wget -q --show-progress -O "$image_file" "$image_url"; then
        print_error "Lỗi khi tải image"
        cd / && rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify files
    local headers_size=$(stat -c%s "$headers_file")
    local image_size=$(stat -c%s "$image_file")
    
    if [ "$headers_size" -lt 1048576 ] || [ "$image_size" -lt 1048576 ]; then
        print_error "File có vẻ bị lỗi (kích thước quá nhỏ)"
        cd / && rm -rf "$temp_dir"
        return 1
    fi
    
    print_success "File hợp lệ - Headers: $(( headers_size / 1024 / 1024 ))MB, Image: $(( image_size / 1024 / 1024 ))MB"
    
    # Install packages
    print_msg "Cài đặt XanMod Kernel..."
	print_info "Quá trình này có thể mất vài phút..."
    if ! dpkg -i "$image_file" "$headers_file"; then
        print_warning "Có lỗi, thử sửa dependencies..."
        apt-get install -f -y
        if ! dpkg -i "$image_file" "$headers_file"; then
            print_error "Cài đặt thất bại!"
            cd / && rm -rf "$temp_dir"
            return 1
        fi
    fi
    
    # Update GRUB
    print_msg "Cập nhật GRUB bootloader..."
    if ! update-grub; then
        print_error "Lỗi khi cập nhật GRUB"
        cd / && rm -rf "$temp_dir"
        return 1
    fi
    
    # Cleanup
    cd / && rm -rf "$temp_dir"
    print_success "Cài đặt hoàn tất!"
    
    return 0
}

# Reset to default kernel
reset_to_default() {
    print_header "RESET VỀ KERNEL MẶC ĐỊNH"
    echo "==============================="
    
    print_warning "Thao tác này sẽ xóa TẤT CẢ kernel XanMod và về kernel mặc định!"
    echo ""
    read -p "Bạn có chắc chắn muốn tiếp tục? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Hủy bỏ thao tác reset"
        return 0
    fi
    
    local kernels_removed=false
    
    # Check if XanMod kernels exist before removal
    if dpkg -l | grep -q 'linux.*xanmod'; then
        kernels_removed=true
    fi
    
    if ! remove_xanmod_kernels "false"; then
        return 1
    fi
    
    print_success "Đã reset về kernel mặc định thành công!"
    
    # Ask for reboot if kernels were actually removed
    if [ "$kernels_removed" = true ]; then
        ask_reboot
    fi
    
    return 0
}

# Show version menu
show_version_menu() {
    local branch=$1
    local branch_name=$2
    
    print_header "CHỌN PHIÊN BẢN XANMOD $branch_name"
    echo "=================================="
    
    print_msg "Đang lấy danh sách phiên bản XanMod $branch..."
    local versions=$(get_versions "$branch")
    if [ -z "$versions" ]; then
        print_error "Không thể lấy danh sách phiên bản!"
        sleep 2
        return 1
    fi
    
    print_success "Tìm thấy $(echo "$versions" | wc -l) phiên bản"
    echo ""
    
    # Convert to array for proper indexing
    local versions_array=()
    while IFS= read -r line; do
        versions_array+=("$line")
    done <<< "$versions"
    
    # Display menu with correct numbering
    for i in "${!versions_array[@]}"; do
        echo "$((i+1)). ${versions_array[$i]}"
    done
    
    echo ""
    read -p "Chọn phiên bản (1-${#versions_array[@]}) hoặc 'q' để quay lại: " choice
    
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        return 0
    fi
    
    if ! [[ "$choice" =~ ^[1-9]$|^10$ ]] || [ "$choice" -gt "${#versions_array[@]}" ]; then
        print_error "Lựa chọn không hợp lệ!"
        sleep 2
        return 1
    fi
    
    # Get selected version using correct array index (choice-1)
    local selected_version="${versions_array[$((choice-1))]}"
    if [ -z "$selected_version" ]; then
        print_error "Phiên bản không tồn tại!"
        sleep 2
        return 1
    fi
    
    print_info "Bạn đã chọn: $selected_version"
    echo ""
    read -p "Tiếp tục cài đặt? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if install_xanmod "$branch" "$selected_version"; then
            print_success "Cài đặt $selected_version thành công!"
            ask_reboot
        else
            print_error "Cài đặt thất bại!"
        fi
    fi
}

# Ask for reboot
ask_reboot() {
    echo ""
    print_warning "HỆ THỐNG CẦN KHỞI ĐỘNG LẠI ĐỂ SỬ DỤNG KERNEL MỚI!"
    echo ""
    read -p "Bạn có muốn khởi động lại ngay bây giờ? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_msg "Khởi động lại hệ thống..."
        sleep 3
        reboot
    else
        print_warning "Nhớ khởi động lại hệ thống để sử dụng kernel mới!"
        print_info "Sử dụng lệnh: sudo reboot"
    fi
}

# Show current kernel info
show_current_kernel() {
    local current_kernel=$(uname -r)
    local xanmod_kernels=$(dpkg -l | grep -E 'linux-(image|headers).*xanmod' | wc -l)
    
    print_info "Kernel hiện tại: $current_kernel"
    if [ "$xanmod_kernels" -gt 0 ]; then
        print_info "Có $((xanmod_kernels / 2)) kernel XanMod được cài đặt"
    else
        print_info "Không có kernel XanMod nào được cài đặt"
    fi
}

# Main menu
show_main_menu() {
    clear
	print_header "╔═══════════════════════════════════════╗"
	print_header "║         XANMOD INSTALLER SCRIPT       ║"
	print_header "║              Phiên bản 1.0            ║"
	print_header "╚═══════════════════════════════════════╝"
    echo ""
    
    show_current_kernel
    echo ""
    
    echo "1. Cài XanMod Edge (Rolling Release)"
    echo "2. Cài XanMod Main (Stable Mainline)" 
    echo "3. Cài XanMod LTS (Long Term Support)"
    echo "4. Reset về kernel mặc định"
    echo "5. Thoát"
    echo ""
}

# Main function
main() {
    # Initial system check
    check_system
    detect_cpu_level
    
    while true; do
        show_main_menu
        read -p "Chọn tùy chọn (1-5): " choice
        
        case $choice in
            1)
                show_version_menu "edge" "EDGE"
                ;;
            2)
                show_version_menu "main" "MAIN"
                ;;
            3)
                show_version_menu "lts" "LTS"
                ;;
            4)
                reset_to_default
                ;;
            5)
                print_success "Thoát chương trình. Cảm ơn bạn đã sử dụng!"
                exit 0
                ;;
            *)
                print_error "Lựa chọn không hợp lệ! Vui lòng chọn 1-5."
                sleep 2
                ;;
        esac
        
        if [ "$choice" != "5" ]; then
            echo ""
            read -p "Nhấn Enter để tiếp tục..." -r
        fi
    done
}

# Run main function
main "$@"
