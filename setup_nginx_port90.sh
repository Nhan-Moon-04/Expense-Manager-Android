#!/bin/bash

# Script tự động cấu hình Nginx port 90 cho Armbian
# Chạy với quyền root: sudo bash setup_nginx_port90.sh

echo "=================================="
echo "  Armbian Nginx Port 90 Setup    "
echo "=================================="
echo ""

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Vui lòng chạy script với quyền root:"
    echo "   sudo bash setup_nginx_port90.sh"
    exit 1
fi

# Step 1: Cài nginx
echo "[1/8] Cài đặt Nginx..."
apt update -qq
apt install -y nginx

# Step 2: Tạo thư mục app
echo "[2/8] Tạo thư mục /var/www/html/app..."
mkdir -p /var/www/html/app
chown -R www-data:www-data /var/www/html/app
chmod -R 755 /var/www/html/app

# Step 3: Tạo file cấu hình nginx
echo "[3/8] Tạo cấu hình Nginx port 90..."
cat > /etc/nginx/sites-available/app-port90 << 'EOF'
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
        
        # CORS headers
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
    
    access_log /var/log/nginx/app-access.log;
    error_log /var/log/nginx/app-error.log;
}
EOF

# Step 4: Kích hoạt site
echo "[4/8] Kích hoạt cấu hình..."
ln -sf /etc/nginx/sites-available/app-port90 /etc/nginx/sites-enabled/

# Step 5: Kiểm tra cấu hình
echo "[5/8] Kiểm tra cấu hình Nginx..."
nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Cấu hình Nginx có lỗi!"
    exit 1
fi

# Step 6: Mở firewall (UFW)
echo "[6/8] Cấu hình firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 90/tcp
    ufw reload
    echo "✓ UFW: Đã mở port 90"
else
    echo "⚠️  UFW không được cài đặt, bỏ qua..."
fi

# Step 7: Restart nginx
echo "[7/8] Restart Nginx..."
systemctl restart nginx
systemctl enable nginx

# Step 8: Tạo file test
echo "[8/8] Tạo file test..."
cat > /var/www/html/app/test.json << 'EOF'
{
    "status": "ok",
    "message": "Nginx port 90 is working!",
    "timestamp": "2026-02-17"
}
EOF

chown www-data:www-data /var/www/html/app/test.json
chmod 644 /var/www/html/app/test.json

# Kiểm tra kết quả
echo ""
echo "=================================="
echo "       Setup Complete! ✅         "
echo "=================================="
echo ""

# Kiểm tra port đang listen
if netstat -tulpn | grep -q ":90"; then
    echo "✓ Nginx đang listen port 90"
    netstat -tulpn | grep ":90"
else
    echo "❌ Nginx KHÔNG listen port 90!"
    exit 1
fi

echo ""
echo "Test URLs:"
echo "  Local:    curl http://localhost:90/app/test.json"
echo "  External: http://nthiennhan.ddns.net:90/app/test.json"
echo ""

# Test local
echo "Testing local connection..."
if curl -s http://localhost:90/app/test.json | grep -q "ok"; then
    echo "✓ Local test PASSED"
else
    echo "❌ Local test FAILED"
fi

echo ""
echo "Next steps:"
echo "1. Test từ browser: http://nthiennhan.ddns.net:90/app/"
echo "2. Chạy script deploy từ Windows: .\\deploy_auto.ps1"
echo "3. Kiểm tra log: tail -f /var/log/nginx/app-access.log"
echo ""
