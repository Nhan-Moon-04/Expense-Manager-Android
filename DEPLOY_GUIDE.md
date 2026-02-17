# 🚀 Hướng Dẫn Deploy Tự Động

## Giới Thiệu

Script `deploy_auto.ps1` giúp bạn tự động:

- ✅ Tăng version trong `pubspec.yaml`
- ✅ Build APK release
- ✅ Tạo file `version.json`
- ✅ Upload APK + JSON lên Armbian server
- ✅ Set quyền truy cập file

## Cài Đặt PuTTY (Khuyến Nghị)

Để script tự động nhập password, cài đặt PuTTY tools:

```powershell
winget install -e --id PuTTY.PuTTY
```

Hoặc tải từ: https://www.putty.org/

**Lưu ý**: Nếu không có PuTTY, script vẫn chạy được nhưng bạn phải nhập password thủ công 2 lần (upload APK + upload JSON).

## Cách Sử Dụng

### 1. Deploy Đơn Giản (Tự Động Tăng Patch)

```powershell
.\deploy_auto.ps1
```

Ví dụ: `1.0.0` → `1.0.1`

### 2. Tăng Minor Version

```powershell
.\deploy_auto.ps1 -IncrementType "minor"
```

Ví dụ: `1.0.5` → `1.1.0`

### 3. Tăng Major Version

```powershell
.\deploy_auto.ps1 -IncrementType "major"
```

Ví dụ: `1.5.3` → `2.0.0`

### 4. Chỉ Định Version Thủ Công

```powershell
.\deploy_auto.ps1 -Version "2.5.0"
```

### 5. Thêm Release Notes

```powershell
.\deploy_auto.ps1 -ReleaseNotes "- Sửa lỗi đồng bộ`n- Cải thiện UI dashboard`n- Thêm tính năng OTA update"
```

### 6. Bắt Buộc Update (Force Update)

```powershell
.\deploy_auto.ps1 -ForceUpdate $true
```

User **bắt buộc** phải update mới dùng được app.

### 7. Kết Hợp Nhiều Tham Số

```powershell
.\deploy_auto.ps1 -IncrementType "minor" -ReleaseNotes "- Tính năng mới quan trọng" -ForceUpdate $true
```

## Các Tham Số

| Tham Số            | Mặc Định              | Mô Tả                                               |
| ------------------ | --------------------- | --------------------------------------------------- |
| `-Version`         | Auto                  | Version mới (vd: "1.2.3"). Nếu bỏ qua, tự động tăng |
| `-IncrementType`   | `patch`               | Loại tăng version: `patch`, `minor`, `major`        |
| `-ReleaseNotes`    | Auto                  | Ghi chú phiên bản. Nếu bỏ qua, tạo tự động          |
| `-ForceUpdate`     | `$false`              | Bắt buộc user phải update                           |
| `-ArmbianHost`     | `nthiennhan.ddns.net` | Domain/IP Armbian server                            |
| `-ArmbianUser`     | `root`                | Username SSH                                        |
| `-ArmbianPassword` | `nguyennhan2004`      | Password SSH                                        |
| `-ArmbianPath`     | `/var/www/html/app`   | Đường dẫn lưu file trên server                      |

## Ví Dụ Thực Tế

### Sửa Lỗi Nhỏ (Patch Release)

```powershell
.\deploy_auto.ps1
```

Output:

```
📦 Current version: 1.0.0+1
📦 New version:     1.0.1 (auto-increment patch)
✓ Updated pubspec.yaml to 1.0.1+2
[1/6] 🔨 Building APK...
...
✅ DEPLOYMENT SUCCESSFUL!
📱 APK URL: http://nthiennhan.ddns.net/app/expense_manager_v1.0.1.apk
```

### Phiên Bản Mới Với Tính Năng Mới (Minor Release)

```powershell
.\deploy_auto.ps1 -IncrementType "minor" -ReleaseNotes "- OTA Update System`n- Foreground Service`n- Notification Queue"
```

### Phiên Bản Lớn (Major Release)

```powershell
.\deploy_auto.ps1 -IncrementType "major" -ReleaseNotes "- Giao diện hoàn toàn mới`n- Hỗ trợ nhiều ngân hàng`n- Tối ưu hiệu suất" -ForceUpdate $true
```

## Quy Trình Script

```
1️⃣  Đọc version hiện tại từ pubspec.yaml
     ↓
2️⃣  Tính toán version mới (auto hoặc manual)
     ↓
3️⃣  Update pubspec.yaml với version + build number mới
     ↓
4️⃣  flutter clean + pub get + build apk --release
     ↓
5️⃣  Tạo version.json với thông tin version và download URL
     ↓
6️⃣  Upload APK lên Armbian (pscp/scp)
     ↓
7️⃣  Upload version.json lên Armbian
     ↓
8️⃣  Set permissions (chmod 644, chown www-data)
     ↓
9️⃣  ✅ DONE!
```

## Lỗi Thường Gặp

### 1. `plink/pscp not found`

**Giải pháp**: Cài đặt PuTTY hoặc chấp nhận nhập password thủ công.

```powershell
winget install -e --id PuTTY.PuTTY
```

### 2. `Upload failed`

**Nguyên nhân**:

- Server Armbian chưa cài nginx
- Thư mục `/var/www/html/app` chưa tồn tại
- Password SSH sai

**Giải pháp**:

```bash
# SSH vào server
ssh root@nthiennhan.ddns.net

# Cài nginx
sudo apt update && sudo apt install nginx

# Tạo thư mục
sudo mkdir -p /var/www/html/app
sudo chown www-data:www-data /var/www/html/app
sudo chmod 755 /var/www/html/app
```

### 3. `flutter command not found`

**Giải pháp**: Đảm bảo Flutter đã được thêm vào PATH.

```powershell
flutter --version
```

### 4. APK không tải được trên điện thoại

**Kiểm tra**:

```bash
# SSH vào server
ssh root@nthiennhan.ddns.net

# Kiểm tra file
ls -la /var/www/html/app

# Test download
curl http://nthiennhan.ddns.net/app/version.json
```

## Tips & Tricks

### 1. Alias PowerShell

Thêm vào `$PROFILE`:

```powershell
function Deploy-Patch { .\deploy_auto.ps1 }
function Deploy-Minor { .\deploy_auto.ps1 -IncrementType "minor" }
function Deploy-Major { .\deploy_auto.ps1 -IncrementType "major" }

Set-Alias -Name dp -Value Deploy-Patch
Set-Alias -Name dm -Value Deploy-Minor
```

Sử dụng:

```powershell
dp  # Deploy patch
dm  # Deploy minor
```

### 2. Git Commit Sau Deploy

```powershell
.\deploy_auto.ps1
git add pubspec.yaml
git commit -m "chore: bump version to $(Get-Content pubspec.yaml | Select-String 'version:' | %{$_ -replace 'version: ',''})"
git push
```

### 3. Setup SSH Key (Không Cần Password)

```powershell
# Tạo SSH key
ssh-keygen -t rsa -b 4096

# Copy key lên server
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh root@nthiennhan.ddns.net "cat >> ~/.ssh/authorized_keys"

# Test
ssh root@nthiennhan.ddns.net
```

Sau đó, bỏ parameter `-ArmbianPassword`.

## Kiểm Tra Kết Quả

Sau khi deploy thành công, test ngay trên trình duyệt:

1. **Version info**:

   ```
   http://nthiennhan.ddns.net/app/version.json
   ```

2. **APK download**:

   ```
   http://nthiennhan.ddns.net/app/expense_manager_v1.0.1.apk
   ```

3. **OTA Update trong app**:
   - Mở app → Settings → Check for Updates
   - Nếu có update, dialog sẽ hiện với release notes và progress bar

## Cấu Trúc File version.json

```json
{
  "version": "1.0.1",
  "minVersion": "1.0.0",
  "downloadUrl": "http://nthiennhan.ddns.net/app/expense_manager_v1.0.1.apk",
  "releaseNotes": "- Sửa lỗi nhỏ\n- Cải thiện hiệu suất",
  "forceUpdate": false,
  "releaseDate": "2025-01-15"
}
```

## So Sánh Version Cũ vs Mới

| Feature                | `deploy_to_armbian.ps1` (cũ) | `deploy_auto.ps1` (mới) |
| ---------------------- | ---------------------------- | ----------------------- |
| Auto-increment version | ❌                           | ✅                      |
| Update pubspec.yaml    | ❌                           | ✅                      |
| Auto password          | ❌                           | ✅ (với PuTTY)          |
| Auto release notes     | ❌                           | ✅                      |
| Better UI              | ⚠️                           | ✅                      |
| Version types          | ❌                           | ✅ (patch/minor/major)  |

## Kết Luận

- ✅ **Đơn giản nhất**: `.\deploy_auto.ps1`
- ✅ **Khuyến nghị**: Cài PuTTY để tự động nhập password
- ✅ **Production**: Setup SSH key để hoàn toàn tự động

---

💡 **Hint**: Sau khi deploy, git commit để lưu version mới!
