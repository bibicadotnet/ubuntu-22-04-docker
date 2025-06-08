# Cài đặt  VPS chạy Docker – cấu hình căn bản và nâng cao [bài viết đang giai đoạn hoàn thiện]

---

### 1. Reinstall OS
Cài 1 OS mới sạch sẽ thông qua Reinstall 
```
sudo -s
cd ~
curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
bash reinstall.sh ubuntu 22.04 --ci --minimal
# root with a default password 123@@@
```
Chọn **22.04** thông dụng, an toàn

---

### 2. Ubuntu Minimal Debloat
Xóa các thứ không cần thiết trên Ubuntu khi chạy Docker
```
wget -qO ubuntu-debloat.sh https://go.bibica.net/ubuntu-22-04-minimal-debloat && sudo bash ubuntu-debloat.sh
```

---

### 3. Cài đặt XanMod Kernel trên Debian
```
wget -qO xanmod-installer.sh https://go.bibica.net/xanmod && bash xanmod-installer.sh
```
Thử nhánh Main, Edge hoặc LTS tùy thích, bản nào cho hiệu năng ping, download, upload tốt hơn thì dùng

- XanMod Edge (Rolling Release): phiên bản mới nhất, có thể gặp một số lỗi quá mới
- XXanMod Main (Stable Mainline): phiên bản ổn định, phần lớn người dùng chọn nhánh này
- XXanMod LTS (Long Term Support): phiên bản ổn định nhất (thường dành cho các hệ thống cần ổn định cao nhất)

Thấy không hiệu quả thì sử dụng tùy chon 4 để về lại Kernel mặc định

---

### 4. System Optimization
```
wget -qO vps.sh https://go.bibica.net/system_optimization_v2 && sudo bash vps.sh
```
Các thiết lập rất cơ bản

---

### Hoàn thành

Sau khi xong 4 bước trên thì `reboot` lại VPS rồi chạy `bash /root/vps.sh --info` để xem thông tin sơ bộ toàn bộ VPS

```
========================================
THÔNG TIN HỆ THỐNG
----------------------------------------
Hostname            : ubuntu
OS                  : Ubuntu 22.04.5 LTS
Kernel              : 6.15.1-x64v3-xanmod1
Arch                : x86_64 (64-bit)
CPU                 : AMD EPYC 7551 32-Core Processor
CPU Cores           : 2
RAM                 : 955 MB total, 133 MB used, 696 MB available
Swap                : 1.0 GB total, 0 MB used, 1.0 GB free
Disk                : 46G total, 4.1G used, 40G free
Public IP           : 146.215.215.158
Private IP          : 10.0.0.197
Main Interface      : ens3
TCP CC              : bbr
Virtualization      : kvm
Load Average        : 0.02, 0.08, 0.04
Uptime              : 4 minutes
Location            : San Jose, US
System Time         : 08/06/2025 at 08:08 AM (GMT+07:00)

========================================
CẤU HÌNH HỆ THỐNG
----------------------------------------
[sysctl.conf]
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
vm.swappiness=10
vm.dirty_ratio=5
vm.dirty_background_ratio=2
vm.dirty_expire_centisecs=1000
vm.dirty_writeback_centisecs=200
vm.vfs_cache_pressure=200
fs.file-max=30000

[Docker 28.2.2]
storage-driver=overlay2
log-driver=json-file
log-opts.max-size=10m
log-opts.max-file=3
max-concurrent-downloads=10
max-concurrent-uploads=10
dns=8.8.8.8,1.1.1.1
userland-proxy=False

[DNS]
nameserver 8.8.8.8
nameserver 1.1.1.1

[Chrony]
Chrony trạng thái : Normal
Sai số đồng bộ    : ±3.05 ms

[Phần mềm đã cài đặt]
curl wget git htop unzip nano zip zstd jq sudo python3 lsof
```

---

### Speedtest Kernel

Thay đổi các phiên bản XanMod Kernel khác nhau, thử speedtest đơn giản, so sánh dùng Kernel nào kết quả tốt hơn thì dùng

Quá trình chạy hơi lâu, nên cho chạy ngầm, lúc nào rảnh thì mở log ra xem lại
```
nohup ./speedtest_kernel.sh >/dev/null 2>&1 &
```
Hoặc có thể thử trực tiếp nếu chạy qua SOCKS5, truy cập vào trang thử download, upload ....

---

### 📊 So sánh hiệu năng download 1GB theo kernel (chuẩn theo `6.8.0-1026-oracle`)

| **Kernel**                | **Thời gian thực (real)** | **Tốc độ trung bình** | **Chênh lệch so với Oracle** |
| ------------------------- | ------------------------- | --------------------- | ---------------------------- |
| **6.8.0-1026-oracle**     | 3 phút 11 giây (\~191.2s) | **5.37 MB/s**         | ⚙️ 0.00% (mốc tham chiếu)    |
| **6.15.1-x64v3-xanmod1**  | 3 phút 2 giây (\~182.5s)  | **5.62 MB/s**         | 🔼 **+4.66%**                |
| **6.14.10-x64v3-xanmod1** | 3 phút 16 giây (\~196.6s) | **5.22 MB/s**         | 🔽 **−2.79%**                |
| **6.12.32-xanmod1**       | 3 phút 7 giây (\~187.5s)  | **5.47 MB/s**         | 🔼 **+1.86%**                |

---

- Kết quả ở trên là đánh giá theo test nhanh 1 lần duy nhất (thường tối thiểu nên chạy 1 bài test 3 lần, lấy kết quả trung bình)
- Nó lại tính theo Kernel +  System Optimization đã cấu hình, sai số sẽ rất nhiều
- Muốn kết quả chính xác hơn, chỉ nên cài duy nhất kernel rồi chạy các bài test để đánh giá
- Trường hợp khác biệt tùy vào CPU, RAM, (I/O) có thể cho ra kết quả khác nhau

