# Hướng Dẫn Cấu Hình Nginx Port 90 trên Armbian

## Bước 1: SSH vào Armbian Server

```bash
ssh root@nthiennhan.ddns.net
# Password: nguyennhan2004
```

## Bước 2: Cài Nginx (nếu chưa có)

```bash
sudo apt update
sudo apt install nginx -y
```

## Bước 3: Tạo Thư Mục App

```bash
# Tạo thư mục lưu APK và version.json
sudo mkdir -p /var/www/html/app

# Set quyền truy cập
sudo chown -R www-data:www-data /var/www/html/app
sudo chmod -R 755 /var/www/html/app
```

## Bước 4: Cấu Hình Nginx Listen Port 90

### Tạo file cấu hình mới:

```bash
sudo nano /etc/nginx/sites-available/app-port90
```

### Paste nội dung sau:

```nginx
server {
    listen 90;
    listen [::]:90;

    server_name nthiennhan.ddns.net;

    root /var/www/html;
    index index.html index.htm;

    # Bật listing cho folder app
    location /app/ {
        alias /var/www/html/app/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;

        # CORS headers để app Android có thể tải file
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
        add_header Access-Control-Allow-Headers 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';

        # Cache control
        add_header Cache-Control "no-cache, must-revalidate";

        # Content type cho APK
        types {
            application/vnd.android.package-archive apk;
        }
    }

    # Access log
    access_log /var/log/nginx/app-access.log;
    error_log /var/log/nginx/app-error.log;
}
```

### Lưu file:

- Nhấn `Ctrl + X`
- Nhấn `Y`
- Nhấn `Enter`

## Bước 5: Kích Hoạt Site

```bash
# Tạo symbolic link
sudo ln -s /etc/nginx/sites-available/app-port90 /etc/nginx/sites-enabled/

# Kiểm tra cấu hình
sudo nginx -t
```

Nếu thấy:

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Thì OK ✅

## Bước 6: Restart Nginx

```bash
sudo systemctl restart nginx

# Kiểm tra trạng thái
sudo systemctl status nginx
```

## Bước 7: Mở Port 90 trên Firewall

### Nếu dùng UFW:

```bash
# Kiểm tra UFW có đang chạy không
sudo ufw status

# Nếu active, thêm rule cho port 90
sudo ufw allow 90/tcp
sudo ufw reload
```

### Nếu dùng iptables:

```bash
# Thêm rule
sudo iptables -A INPUT -p tcp --dport 90 -j ACCEPT

# Lưu lại
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Nếu không có firewall:

Không cần làm gì, bỏ qua bước này.

## Bước 8: Kiểm Tra Port Đã Mở

```bash
# Kiểm tra nginx đang listen port 90
sudo netstat -tulpn | grep :90

# Hoặc
sudo ss -tulpn | grep :90
```

Phải thấy kết quả:

```
tcp        0      0 0.0.0.0:90              0.0.0.0:*               LISTEN      1234/nginx: master
tcp6       0      0 :::90                   :::*                    LISTEN      1234/nginx: master
```

## Bước 9: Test từ Server

```bash
# Test từ chính server
curl http://localhost:90/app/version.json

# Nếu file chưa có, tạo file test
echo '{"version":"1.0.0"}' | sudo tee /var/www/html/app/version.json
sudo chown www-data:www-data /var/www/html/app/version.json
sudo chmod 644 /var/www/html/app/version.json

# Test lại
curl http://localhost:90/app/version.json
```

## Bước 10: Test từ Browser

Mở trình duyệt và truy cập:

```
http://nthiennhan.ddns.net:90/app/
```

Bạn sẽ thấy danh sách file trong thư mục `/var/www/html/app/`.

## Bước 11: Deploy APK từ PowerShell

Quay lại Windows, chạy script deploy:

```powershell
.\deploy_auto.ps1
```

Script sẽ:

1. Build APK
2. Tạo version.json với URL port 90
3. Upload APK lên `/var/www/html/app/`
4. Upload version.json
5. Set permissions

## Kiểm Tra Kết Quả

### Trong Browser:

1. Version info:

   ```
   http://nthiennhan.ddns.net:90/app/version.json
   ```

2. APK file:

   ```
   http://nthiennhan.ddns.net:90/app/expense_manager_v1.0.3.apk
   ```

3. Danh sách file:
   ```
   http://nthiennhan.ddns.net:90/app/
   ```

### Trên điện thoại:

Mở app → Settings → Kiểm tra update → Sẽ tải từ port 90

## Troubleshooting

### Lỗi "Connection refused"

```bash
# Kiểm tra nginx đang chạy
sudo systemctl status nginx

# Nếu không chạy, start lại
sudo systemctl start nginx

# Kiểm tra port 90
sudo netstat -tulpn | grep :90
```

### Lỗi "403 Forbidden"

```bash
# Check permissions
ls -la /var/www/html/app/

# Sửa permissions
sudo chown -R www-data:www-data /var/www/html/app
sudo chmod -R 755 /var/www/html/app
sudo chmod 644 /var/www/html/app/*
```

### Lỗi "404 Not Found"

```bash
# Kiểm tra file có tồn tại không
ls -la /var/www/html/app/

# Kiểm tra nginx config
sudo nginx -t

# Xem log
sudo tail -f /var/log/nginx/app-error.log
```

### Không thể tải APK từ app

```bash
# Kiểm tra CORS headers
curl -I http://localhost:90/app/version.json

# Phải thấy:
# Access-Control-Allow-Origin: *
```

### Port 90 bị router block

Port 90 có thể bị router/ISP block. Thử:

1. **Port 8090**:

   ```bash
   # Đổi trong nginx config
   sudo nano /etc/nginx/sites-available/app-port90
   # Đổi listen 90 thành listen 8090

   # Restart
   sudo systemctl restart nginx
   ```

2. **Cập nhật code**:
   - Đổi trong `deploy_auto.ps1`: `-ArmbianPort = 8090`
   - Đổi trong `version_service.dart`: `:8090`

## Port Forwarding trên Router

Nếu Armbian ở sau router, cần port forwarding:

1. Đăng nhập router admin (thường `192.168.1.1`)
2. Tìm **Port Forwarding** / **Virtual Server**
3. Thêm rule:
   - **External Port**: 90
   - **Internal IP**: `192.168.x.x` (IP của Armbian)
   - **Internal Port**: 90
   - **Protocol**: TCP
4. Save và restart router

## Tổng Kết

Sau khi setup xong:

| Component    | URL                                                                |
| ------------ | ------------------------------------------------------------------ |
| Version info | `http://nthiennhan.ddns.net:90/app/version.json`                   |
| APK download | `http://nthiennhan.ddns.net:90/app/expense_manager_v{version}.apk` |
| File listing | `http://nthiennhan.ddns.net:90/app/`                               |

✅ App sẽ tự động kiểm tra update từ Armbian server port 90
✅ Không cần Google Play Store
✅ Deploy tự động bằng PowerShell script

---

**Lưu ý**: Nếu vẫn không hoạt động, kiểm tra:

1. Firewall trên Armbian
2. Port forwarding trên router
3. ISP có block port 90 không
4. DDNS nthiennhan.ddns.net có hoạt động không (`ping nthiennhan.ddns.net`)
