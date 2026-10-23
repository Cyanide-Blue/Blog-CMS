#!/usr/bin/env bash
set -e

EVIDENCE_FILE="/home/trung/blogcms/evidence/buoc3-nginx.txt"
BASE_HTTPS="https://localhost"
BASE_HTTP="http://localhost"
COOKIE_JAR=$(mktemp)
TMP_IMG="/tmp/test_cover_nginx.png"

trap "rm -f $COOKIE_JAR $TMP_IMG" EXIT

cd /home/trung/blogcms

# Create valid test PNG
python3 -c "import base64; open('$TMP_IMG', 'wb').write(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='))"

echo "================================================================================" | tee "$EVIDENCE_FILE"
echo "BẰNG CHỨNG KIỂM TRA BƯỚC 3: NGINX REVERSE PROXY + HTTPS TỰ KÝ + SECURITY HEADERS" | tee -a "$EVIDENCE_FILE"
echo "MSSV: DTC245180035 - Họ và tên: Hà Đức Trung" | tee -a "$EVIDENCE_FILE"
echo "Thời gian ghi nhận: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" | tee -a "$EVIDENCE_FILE"
echo "================================================================================" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "1. KIỂM TRA CÚ PHÁP CẤU HÌNH NGINX (docker compose exec nginx nginx -t)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
docker compose exec -T nginx nginx -t 2>&1 | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "2. REDIRECT HTTP -> HTTPS (curl -I http://localhost - KỲ VỌNG: 301 MOVED PERMANENTLY)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
curl -sI "$BASE_HTTP" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "3. KIỂM TRA HTTPS VÀ TOÀN BỘ SECURITY HEADERS (curl -kI https://localhost)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
curl -skI "$BASE_HTTPS" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "4. KIỂM TRA TRANG CHỦ VÀ NGUỒN CẤP RSS QUA HTTPS" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "-> Kiểm tra tải trang chủ (HTML length):" | tee -a "$EVIDENCE_FILE"
curl -sk "$BASE_HTTPS/" | wc -c | awk '{print "   Kích thước HTML trang chủ:", $1, "bytes"}' | tee -a "$EVIDENCE_FILE"

echo "-> Header nguồn cấp RSS (/rss.xml):" | tee -a "$EVIDENCE_FILE"
curl -skI "$BASE_HTTPS/rss.xml" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "5. KIỂM TRA TRUY CẬP PGADMIN QUA ĐƯỜNG DẪN CON /pgadmin/" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
curl -skIL "$BASE_HTTPS/pgadmin/" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "6. XÁC NHẬN CỔNG NỘI BỘ 3000 VÀ 5050 ĐÃ ĐƯỢC ĐÓNG KHỎI TRUY CẬP TỪ BÊN NGOÀI" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "-> Thử kết nối trực tiếp cổng 3000 (web):" | tee -a "$EVIDENCE_FILE"
curl -sI --connect-timeout 2 http://localhost:3000 2>&1 | tee -a "$EVIDENCE_FILE" || echo "   => CỔNG 3000 ĐÃ ĐÓNG HOÀN TOÀN (CONNECTION REFUSED)" | tee -a "$EVIDENCE_FILE"

echo "-> Thử kết nối trực tiếp cổng 5050 (pgadmin):" | tee -a "$EVIDENCE_FILE"
curl -sI --connect-timeout 2 http://localhost:5050 2>&1 | tee -a "$EVIDENCE_FILE" || echo "   => CỔNG 5050 ĐÃ ĐÓNG HOÀN TOÀN (CONNECTION REFUSED)" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "7. THÔNG TIN CHỨNG CHỈ SSL/TLS TỰ KÝ (openssl s_client)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
openssl s_client -connect localhost:443 </dev/null 2>/dev/null | openssl x509 -noout -subject -dates -ext subjectAltName | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "8. ĐĂNG NHẬP VÀ UPLOAD ẢNH BÌA QUA HTTPS (COOKIE JAR + MAGIC BYTES + STATIC CACHE)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
LOGIN_PAGE=$(curl -sk -c "$COOKIE_JAR" "$BASE_HTTPS/login")
CSRF_LOGIN=$(echo "$LOGIN_PAGE" | grep -o 'name="_csrf" value="[^"]*"' | head -n 1 | sed 's/name="_csrf" value="//;s/"//')
echo "  -> CSRF token: $CSRF_LOGIN" | tee -a "$EVIDENCE_FILE"

echo "  -> Thực hiện đăng nhập tài khoản tacgia01 qua HTTPS..." | tee -a "$EVIDENCE_FILE"
LOGIN_RESP=$(curl -sk -i -b "$COOKIE_JAR" -c "$COOKIE_JAR" -X POST "$BASE_HTTPS/login" \
  -d "_csrf=${CSRF_LOGIN}" \
  -d "username=tacgia01" \
  -d "password=123456")
LOGIN_STATUS=$(echo "$LOGIN_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status đăng nhập: $LOGIN_STATUS (Kỳ vọng: 302 Redirect)" | tee -a "$EVIDENCE_FILE"

EDITOR_PAGE=$(curl -sk -b "$COOKIE_JAR" "$BASE_HTTPS/author/posts/new")
CSRF_EDITOR=$(echo "$EDITOR_PAGE" | grep -o 'value="[^"]*" id="csrf-token-field"' | head -n 1 | sed 's/value="//;s/" id="csrf-token-field"//')

echo "  -> Upload ảnh bìa mới qua HTTPS (multipart/form-data)..." | tee -a "$EVIDENCE_FILE"
UPLOAD_RESP=$(curl -sk -i -b "$COOKIE_JAR" -c "$COOKIE_JAR" -X POST "$BASE_HTTPS/author/posts/save?_csrf=${CSRF_EDITOR}" \
  -F "_csrf=${CSRF_EDITOR}" \
  -F "title=Bài Viết Thử Nghiệm Upload Ảnh Bìa HTTPS" \
  -F "category_id=1" \
  -F "excerpt=Kiểm tra upload ảnh qua Nginx Reverse Proxy HTTPS" \
  -F "content=Nội dung bài viết thử nghiệm ảnh bìa qua HTTPS" \
  -F "action=save_draft" \
  -F "cover_image=@${TMP_IMG};type=image/png")
UPLOAD_STATUS=$(echo "$UPLOAD_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status upload bài viết: $UPLOAD_STATUS (Kỳ vọng: 302 Redirect)" | tee -a "$EVIDENCE_FILE"

# Lấy đường dẫn file vừa tải lên từ DB
UPLOADED_PATH=$(docker compose exec -T db psql -U blogcms_app -d blogcms -t -A -c "SELECT cover_image_path FROM posts WHERE title LIKE '%Upload Ảnh Bìa HTTPS%' LIMIT 1")
echo "  -> Đường dẫn ảnh được lưu: ${UPLOADED_PATH}" | tee -a "$EVIDENCE_FILE"

echo "  -> Kiểm tra tải ảnh bìa qua HTTPS (curl -skI https://localhost${UPLOADED_PATH}):" | tee -a "$EVIDENCE_FILE"
curl -skI "${BASE_HTTPS}${UPLOADED_PATH}" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "9. TRẠNG THÁI TOÀN BỘ CÁC SERVICE TRONG STACK (docker compose ps)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
docker compose ps | tee -a "$EVIDENCE_FILE"

echo -e "\n================================================================================" | tee -a "$EVIDENCE_FILE"
echo "HOÀN THÀNH TẤT CẢ KIỂM TRA BƯỚC 3!" | tee -a "$EVIDENCE_FILE"
echo "File lưu trữ: $EVIDENCE_FILE" | tee -a "$EVIDENCE_FILE"
echo "================================================================================" | tee -a "$EVIDENCE_FILE"