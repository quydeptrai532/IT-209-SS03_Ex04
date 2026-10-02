#!/usr/bin/env bash
#
# Bài 4 (Session 03) - Nginx Virtual Hosts chạy song song cổng 8080 và 8090
#   - Cổng 8080 -> /var/www/beta-app/html       (Beta App)
#   - Cổng 8090 -> /var/www/internal-app/html   (Internal App)
#
# Cách dùng (trên máy chủ Ubuntu, quyền root):
#   chmod +x setup.sh
#   sudo ./setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Cài Nginx (nếu chưa có)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx

echo "==> Tạo thư mục web"
mkdir -p /var/www/beta-app/html
mkdir -p /var/www/internal-app/html

echo "==> Copy index.html"
cp "$SCRIPT_DIR/www/beta-app/html/index.html"      /var/www/beta-app/html/index.html
cp "$SCRIPT_DIR/www/internal-app/html/index.html"  /var/www/internal-app/html/index.html

echo "==> Phân quyền web (www-data đọc được)"
chown -R www-data:www-data /var/www/beta-app /var/www/internal-app
chmod -R 755 /var/www/beta-app /var/www/internal-app

echo "==> Cấu hình Nginx: multi-port.conf"
cp "$SCRIPT_DIR/nginx/multi-port.conf" /etc/nginx/sites-available/multi-port.conf
ln -sf /etc/nginx/sites-available/multi-port.conf /etc/nginx/sites-enabled/multi-port.conf
# Bỏ default site để tránh trùng cổng 80 nếu cần
nginx -t
systemctl restart nginx 2>/dev/null || service nginx restart

echo "==> Mở cổng trên UFW"
if command -v ufw >/dev/null 2>&1; then
  ufw allow 8080/tcp
  ufw allow 8090/tcp
  ufw reload || true
fi

echo "==> Kiểm tra"
curl -s -o /dev/null -w "  Cong 8080 -> HTTP %{http_code}\n" http://localhost:8080/
curl -s -o /dev/null -w "  Cong 8090 -> HTTP %{http_code}\n" http://localhost:8090/

echo "==> Hoàn tất."
