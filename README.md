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

### 3. System Optimization
```
wget -qO vps.sh https://go.bibica.net/ubuntu-22-04-basic-optimization && sudo bash vps.sh
```
Các thiết lập rất cơ bản

---

### 4. Cài đặt XanMod Kernel trên Debian
```
wget -qO xanmod-installer.sh https://go.bibica.net/xanmod && bash xanmod-installer.sh
```
Thử nhánh Main, Edge hoặc LTS tùy thích, bản nào cho hiệu năng ping, download, upload tốt hơn thì dùng

- XanMod Edge (Rolling Release): phiên bản mới nhất, có thể gặp một số lỗi quá mới
- XXanMod Main (Stable Mainline): phiên bản ổn định, phần lớn người dùng chọn nhánh này
- XXanMod LTS (Long Term Support): phiên bản ổn định nhất (thường dành cho các hệ thống cần ổn định cao nhất)

Thấy không hiệu quả thì sử dụng tùy chon 4 để về lại Kernel mặc định

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
Kernel              : 6.15.2-x64v3-xanmod1
Arch                : x86_64 (64-bit)
CPU                 : AMD EPYC 7551 32-Core Processor
CPU Cores           : 2
RAM                 : 955 MB total, 139 MB used, 690 MB available
Swap                : 2.0 GB total, 0 MB used, 2.0 GB free
Disk                : 46G total, 5.1G used, 39G free
Public IP           : 123.123.123.123
Private IP          : 10.0.0.117
Main Interface      : ens3
TCP CC              : bbr
Virtualization      : kvm
Load Average        : 0.29, 0.09, 0.03
Uptime              : 0 minutes
Location            : San Jose, US
System Time         : 12/06/2025 at 11:11 PM (GMT+07:00)

========================================
CẤU HÌNH HỆ THỐNG
----------------------------------------
[Disable IPv6]
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

[Memory Config]
vm.swappiness = 10

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
Sai số đồng bộ    : ±1.87 ms

[Phần mềm đã cài đặt]
curl wget git htop unzip nano zip zstd jq sudo python3 lsof
```

---

### Speedtest Kernel

Thay đổi các phiên bản XanMod Kernel khác nhau, thử speedtest đơn giản, so sánh dùng Kernel nào kết quả tốt hơn thì dùng

Quá trình chạy hơi lâu, nên cho chạy ngầm, lúc nào rảnh thì mở log ra xem lại
```
nohup bash -c "$(curl -fsSL wget -qO benchmark.sh https://go.bibica.net/kernel_benchmark && bash benchmark.sh)" >/dev/null 2>&1 &
```
Hoặc có thể thử trực tiếp nếu chạy qua SOCKS5, truy cập vào trang thử download, upload ....

---
XanMod Kernel thường không cho ra điểm số TCP stack cao, dùng vì đơn giản muốn thử xem thế nào 😅

<details>
<summary><strong>Ubuntu 22.04 Kernel: 6.15.2-x64v3-xanmod1</strong></summary>

<pre><code>[23:13:36] INFO: Hostname: ubuntu
[23:13:36] INFO: OS: Ubuntu 22.04.5 LTS
[23:13:36] INFO: Kernel: 6.15.2-x64v3-xanmod1
[23:13:36] INFO: Arch: x86_64 (64-bit)
[23:13:36] INFO: CPU: AMD EPYC 7551 32-Core Processor
[23:13:36] INFO: CPU Cores: 2
[23:13:36] INFO: RAM: 955 MB total, 157 MB used, 676 MB available
[23:13:36] INFO: Swap: 2.0 GB total, 0 MB used, 2.0 GB free
[23:13:36] INFO: Disk: 46G total, 5.1G used, 39G free
[23:22:19] SUMMARY: Kernel: 6.15.2-x64v3-xanmod1
=============================================
               FINAL RESULTS
=============================================
[23:22:19] SUMMARY: TCP Loopback Performance:
[23:22:19] SUMMARY:   Valid tests: 30/30
[23:22:19] SUMMARY:   Average: 4.62 Gbps
[23:22:19] SUMMARY:   Min: 4.48 Gbps
[23:22:19] SUMMARY:   Max: 4.76 Gbps
[23:22:19] SUMMARY:   Std Dev: 0.07 Gbps
[23:22:19] SUMMARY:   Coefficient of Variation: 1.52%
[23:22:19] SUMMARY: Performance Rating: AVERAGE (2-5 Gbps)
[23:22:19] SUMMARY: Consistency: EXCELLENT (CV <= 5%)</code></pre>
</details>

<details>
<summary><strong>Ubuntu 25.04 Kernel: 6.14.0-1005-oracle</strong></summary>

<pre><code>[06:17:00] INFO: OS: Ubuntu 25.04
[06:17:00] INFO: Kernel: 6.14.0-1005-oracle
[06:17:00] INFO: Arch: x86_64 (64-bit)
[06:17:00] INFO: CPU: AMD EPYC 7551 32-Core Processor
[06:17:00] INFO: CPU Cores: 2
[06:17:00] INFO: RAM: 956 MB total, 291 MB used, 542 MB available
[06:17:00] INFO: Swap: 2.0 GB total, 58 MB used, 1.9 GB free
[06:17:00] INFO: Disk: 46G total, 4.3G used, 39G free
[06:25:40] SUMMARY: Kernel: 6.14.0-1005-oracle
=============================================
               FINAL RESULTS
=============================================
[06:25:40] SUMMARY: TCP Loopback Performance:
[06:25:40] SUMMARY:   Valid tests: 30/30
[06:25:40] SUMMARY:   Average: 7.04 Gbps
[06:25:40] SUMMARY:   Min: 6.77 Gbps
[06:25:40] SUMMARY:   Max: 7.31 Gbps
[06:25:40] SUMMARY:   Std Dev: 0.14 Gbps
[06:25:40] SUMMARY:   Coefficient of Variation: 1.99%
[06:25:40] SUMMARY: Performance Rating: GOOD (5-10 Gbps)
[06:25:40] SUMMARY: Consistency: EXCELLENT (CV <= 5%)</code></pre>
</details>
