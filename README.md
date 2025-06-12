# Cài đặt  VPS chạy Docker – cấu hình căn bản và nâng cao [bài viết đang giai đoạn hoàn thiện]

Note: toàn bộ nội dung bài này, thuần túy là thử nghiệm, dùng cá nhân, không nên áp dụng vào các hệ thống đang vận hành ổn định

Tất cả các setting đều có thể sẽ bị điều chỉnh lại, cho tới khi dòng note này bị xóa bỏ 😅

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
wget -qO debloat.sh https://go.bibica.net/ubuntu-22-04-minimal-debloat && sudo bash debloat.sh
```
Bản Debloat viết riêng khi sử dụng Ubuntu 22.04 Minimal cài qua bộ reinstall của bin456789

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

Sau khi xong 4 bước trên thì `reboot` lại VPS rồi xem lại thông tin sơ bộ toàn bộ VPS
```
bash /root/vps.sh --info
``` 
Lượng RAM sử dụng giao động **130MB - 140MB**
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
nohup bash -c "$(curl -fsSL https://raw.githubusercontent.com/bibicadotnet/ubuntu-22-04-docker/main/speedtest_kernel.sh)" >/dev/null 2>&1 &
```
Hoặc có thể thử trực tiếp nếu chạy qua SOCKS5, truy cập vào trang thử download, upload ....

---
XanMod Kernel thường không cho ra điểm số cao, dùng vì đơn giản muốn thử xem thế nào 😅
