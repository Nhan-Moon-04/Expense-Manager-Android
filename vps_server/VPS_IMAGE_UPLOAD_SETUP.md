# Hướng Dẫn Cấu Hình Upload Ảnh Lên VPS Armbian / Ubuntu (Port 90)

## Bước 1: SSH vào VPS
```bash
ssh root@nthiennhan.ddns.net
# Nhập mật khẩu
```

## Bước 2: Cài đặt PHP-FPM (nếu chưa có)
```bash
sudo apt update
sudo apt install php-fpm php-cli -y
```

## Bước 3: Tạo thư mục lưu trữ ảnh và thư mục API
```bash
# 1. Tạo thư mục api và thư mục uploads
sudo mkdir -p /var/www/html/api
sudo mkdir -p /var/www/html/uploads/receipts

# 2. Phân quyền cho web server ghi file
sudo chown -R www-data:www-data /var/www/html/uploads
sudo chown -R www-data:www-data /var/www/html/api
sudo chmod -R 775 /var/www/html/uploads
```

## Bước 4: Copy file `upload.php` vào `/var/www/html/api/upload.php`
Bạn có thể copy nội dung file `vps_server/upload.php` từ máy tính lên VPS:
```bash
sudo nano /var/www/html/api/upload.php
# Dán toàn bộ nội dung file upload.php vào rồi nhấn Ctrl+O -> Enter -> Ctrl+X
```

Set quyền cho file:
```bash
sudo chown www-data:www-data /var/www/html/api/upload.php
sudo chmod 644 /var/www/html/api/upload.php
```

## Bước 5: Cập nhật cấu hình Nginx Port 90
```bash
sudo nano /etc/nginx/sites-available/app-port90
```
Dán cấu hình từ file `vps_server/nginx_port90_upload.conf` vào.

Kiểm tra cú pháp và khởi động lại Nginx:
```bash
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl restart php*-fpm
```

## Bước 6: Kiểm tra Upload thử nghiệm
Từ máy tính hoặc trên VPS chạy lệnh curl sau:
```bash
curl -F "file=@/path/to/test.jpg" http://nthiennhan.ddns.net:90/api/upload.php
```
Nếu nhận được JSON: `{"success": true, "url": "http://nthiennhan.ddns.net:90/uploads/receipts/..."}` là hoàn tất 100%!
