# Cài đặt  VPS chạy Docker – cấu hình căn bản và nâng cao [Giai đoạn hoàn thiện]

---

### Reinstall OS
Cài 1 OS mới sạch sẽ thông qua Reinstall 
```
sudo -s
cd ~
curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
bash reinstall.sh ubuntu 22.04 --minimal
# root with a default password 123@@@
```
Chọn **22.04** thông dụng, an toàn

---

### Cài đặt XanMod Kernel trên Debian
```
wget -qO xanmod-installer.sh https://go.bibica.net/xanmod && bash xanmod-installer.sh
```
Thử nhánh Main, Edge hoặc LTS tùy thích, bản nào cho hiệu năng ping, download, upload tốt hơn thì dùng

- XanMod Edge (Rolling Release): phiên bản mới nhất, có thể gặp một số lỗi quá mới
- XXanMod Main (Stable Mainline): phiên bản ổn định, phần lớn người dùng chọn nhánh này
- XXanMod LTS (Long Term Support): phiên bản ổn định nhất (thường dành cho các hệ thống cần ổn định cao nhất)

Thấy không hiệu quả thì sử dụng tùy chon 4 để về lại Kernel mặc định

---

### System Optimization
```
wget -qO vps.sh https://go.bibica.net/system_optimization_v2 && sudo bash vps.sh
```
Các thiết lập rất an toàn, có thể yên tâm sử dụng

- Trung bình sau khi cài đặt xong tất cả mọi thứ, hệ thống sử dụng khoảng **150MB RAM**

---

### Speedtest Kernel
Thay đổi các phiên bản XanMod Kernel khác nhau, thử speedtest đơn giản, so sánh dùng Kernel nào kết quả tốt hơn thì dùng

Ví dụ:
```
time wget http://speedtest.tele2.net/1GB.zip -O /dev/null
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

