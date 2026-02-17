# Hướng dẫn setup Armbian Server để cập nhật APK

## 1. Cài đặt HTTP Server trên Armbian

Trên Armbian box của bạn (192.168.1.200), chạy lệnh sau:

```bash
# Cài đặt nginx hoặc apache
sudo apt update
sudo apt install nginx

# Hoặc dùng python simple http server
```

## 2. Tạo thư mục app

```bash
# Tạo folder để chứa APK và version.json
sudo mkdir -p /var/www/html/app
cd /var/www/html/app
```

## 3. Upload files

Bạn cần upload 2 file vào `/var/www/html/app/`:

### File 1: version.json

```json
{
  "latestVersion": "1.0.1",
  "minVersion": "1.0.0",
  "downloadUrl": "http://192.168.1.200/app/expense_manager_v1.0.1.apk",
  "releaseNotes": "- Tự động ghi nhận giao dịch từ thông báo ngân hàng\n- Chạy ngầm không bị kill\n- Đồng bộ số dư tự động\n- Sửa lỗi hiển thị",
  "forceUpdate": false
}
```

### File 2: APK file

Copy file APK đã build vào folder này với tên: `expense_manager_v1.0.1.apk`

```bash
# Upload qua scp từ máy tính
scp expense_manager_v1.0.1.apk root@192.168.1.200:/var/www/html/app/

# Hoặc dùng FileZilla/WinSCP
```

## 4. Set permissions

```bash
sudo chmod 644 /var/www/html/app/*
sudo chown www-data:www-data /var/www/html/app/*
```

## 5. Test

Mở browser và truy cập:

- http://192.168.1.200/app/version.json (should show JSON)
- http://192.168.1.200/app/expense_manager_v1.0.1.apk (should download APK)

## 6. Cách cập nhật version mới

Khi có version mới:

1. Build APK mới
2. Upload APK lên Armbian với tên: `expense_manager_v{version}.apk`
3. Sửa `version.json`:
   - Tăng `latestVersion`
   - Update `downloadUrl` với tên APK mới
   - Update `releaseNotes`
   - Nếu bắt buộc update: set `forceUpdate: true`

4. App sẽ tự động check version khi:
   - Mở app
   - Vào trang Settings
   - User nhấn nút "Kiểm tra cập nhật"

## 7. Troubleshooting

Nếu không download được APK:

```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Restart nginx
sudo systemctl restart nginx
```

## Version Format

Version phải theo format: `major.minor.patch` (vd: 1.2.3)

- `latestVersion`: Phiên bản mới nhất có sẵn
- `minVersion`: Phiên bản tối thiểu, user dưới version này bắt buộc update
- `forceUpdate`: true = bắt buộc update, false = tùy chọn

## Notes

- Đổi IP `192.168.1.200` thành IP thực tế của Armbian box
- Đảm bảo firewall cho phép port 80 (HTTP)
- Nên dùng HTTPS cho production (setup Let's Encrypt)
