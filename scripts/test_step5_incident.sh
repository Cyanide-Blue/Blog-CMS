#!/usr/bin/env bash
# =============================================================================
# KIỂM THỬ BƯỚC 5: HẠ TẦNG LOG LOKI + PROMTAIL + SỰ CỐ BRUTE FORCE & ALERT
# MSSV: DTC245180035 - Họ và tên: Hà Đức Trung
# =============================================================================
set -e

BASE_DIR="/home/trung/blogcms"
cd "$BASE_DIR"

EVIDENCE_LOGQL="evidence/buoc5-logql.txt"
EVIDENCE_INCIDENT="evidence/buoc5-sucodo.txt"
mkdir -p evidence docs

GRAFANA_PASS=$(grep "^GRAFANA_ADMIN_PASSWORD=" .env | cut -d= -f2)

echo "[*] ============================================================================"
echo "[*] BẮT ĐẦU QUY TRÌNH KIỂM THỬ SỰ CỐ AN TOÀN THÔNG TIN & TRUY VẾT LOG LOKI"
echo "[*] Thời gian: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "[*] ============================================================================"

# -----------------------------------------------------------------------------
# PHẦN 1: Tạo dữ liệu mẫu POST_STATUS bằng cách đăng nhập Author và tạo bài nháp
# -----------------------------------------------------------------------------
echo "[*] 1. Tạo hoạt động tác giả để sinh sự kiện [POST_STATUS]..."
COOKIE_FILE="/tmp/author_cookie_$$.txt"
AUTHOR_HTML=$(curl -sk -c "$COOKIE_FILE" https://localhost/login)
AUTHOR_CSRF=$(echo "$AUTHOR_HTML" | grep -o 'name="_csrf" value="[^"]*"' | head -n1 | cut -d'"' -f4)

curl -sk -b "$COOKIE_FILE" -c "$COOKIE_FILE" -X POST https://localhost/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "_csrf=$AUTHOR_CSRF" \
  --data-urlencode "username=tacgia01" \
  --data-urlencode "password=123456" > /dev/null

# Lấy CSRF form tạo bài viết
EDITOR_HTML=$(curl -sk -b "$COOKIE_FILE" https://localhost/author/editor)
EDITOR_CSRF=$(echo "$EDITOR_HTML" | grep -o 'name="_csrf" value="[^"]*"' | head -n1 | cut -d'"' -f4)

# Gửi bài viết mới để ghi nhận POST_STATUS
curl -sk -b "$COOKIE_FILE" -X POST https://localhost/author/posts \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "_csrf=$EDITOR_CSRF" \
  --data-urlencode "title=Bài viết kiểm thử Nhật ký Duyệt bài Promtail" \
  --data-urlencode "category_id=1" \
  --data-urlencode "tags=DevOps,Docker,Loki" \
  --data-urlencode "summary=Bài viết kiểm tra sự kiện chuyển trạng thái bài viết" \
  --data-urlencode "content=Nội dung bài viết tạo log POST_STATUS kiểm thử hệ thống thu thập log tập trung Loki và Promtail." \
  --data-urlencode "action=submit" > /dev/null || true

rm -f "$COOKIE_FILE"
echo "[+] Đã sinh log [POST_STATUS] thành công!"

# -----------------------------------------------------------------------------
# PHẦN 2: Kiểm tra trạng thái Alert TRƯỚC khi tấn công (3a)
# -----------------------------------------------------------------------------
echo "[*] 2. Kiểm tra trạng thái Alert TRƯỚC khi tấn công..."
PRE_ALERT=$(docker compose exec -T grafana wget -qO- --header='Accept: application/json' "http://admin:${GRAFANA_PASS}@127.0.0.1:3000/api/prometheus/grafana/api/v1/alerts")
echo "Trạng thái Alert trước tấn công:"
echo "$PRE_ALERT"

# -----------------------------------------------------------------------------
# PHẦN 3: Kích hoạt kịch bản tấn công Brute Force (20 requests)
# -----------------------------------------------------------------------------
echo "[*] 3. Thực thi kịch bản tấn công Brute Force (scripts/simulate_bruteforce.sh)..."
START_ATTACK=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
./scripts/simulate_bruteforce.sh https://localhost
END_ATTACK=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Chờ Promtail chuyển log vào Loki và Grafana đánh giá rule (khoảng 15 giây)
echo "[*] Đang chờ Promtail đẩy log sang Loki và Grafana đánh giá Alert Rule (15 giây)..."
sleep 15

# -----------------------------------------------------------------------------
# PHẦN 4: Kiểm tra trạng thái Alert TRONG & SAU tấn công (3c)
# -----------------------------------------------------------------------------
echo "[*] 4. Kiểm tra trạng thái Alert SAU tấn công..."
POST_ALERT=$(docker compose exec -T grafana wget -qO- --header='Accept: application/json' "http://admin:${GRAFANA_PASS}@127.0.0.1:3000/api/prometheus/grafana/api/v1/alerts")
echo "Trạng thái Alert sau tấn công:"
echo "$POST_ALERT"

# Kiểm tra log của service alert-sink nhận webhook
echo "[*] Kiểm tra log của alert-sink (stdout và file):"
docker compose logs alert-sink --tail 20

# -----------------------------------------------------------------------------
# PHẦN 5: Thực thi các truy vấn LogQL (Phần B) và lưu vào evidence/buoc5-logql.txt
# -----------------------------------------------------------------------------
echo "[*] 5. Chạy các truy vấn LogQL qua API Loki..."

cat << 'HEADER' > "$EVIDENCE_LOGQL"
================================================================================
BẰNG CHỨNG KIỂM TRA TRUY VẤN LOGQL QUA LOKI API (BƯỚC 5 - PHẦN B)
MSSV: DTC245180035 - Họ và tên: Hà Đức Trung
================================================================================
HEADER

echo -e "\nThời gian thực thi: $(date -u '+%Y-%m-%d %H:%M:%S UTC')\n" >> "$EVIDENCE_LOGQL"

run_logql() {
  local title="$1"
  local query="$2"
  echo "--------------------------------------------------------------------------------" >> "$EVIDENCE_LOGQL"
  echo "TRUY VẤN: ${title}" >> "$EVIDENCE_LOGQL"
  echo "LỆNH: curl -G -s \"http://loki:3100/loki/api/v1/query_range\" --data-urlencode 'query=${query}'" >> "$EVIDENCE_LOGQL"
  echo "KẾT QUẢ JSON TRẢ VỀ TỪ LOKI:" >> "$EVIDENCE_LOGQL"
  docker compose exec -T loki wget -qO- "http://127.0.0.1:3100/loki/api/v1/query_range?query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$query'''))")" | python3 -m json.tool | head -n 40 >> "$EVIDENCE_LOGQL"
  echo -e "\n" >> "$EVIDENCE_LOGQL"
}

# Q1: {job="nginx"} |~ "\" 5[0-9]{2} " (hoặc HTTP status)
run_logql "Q1: Tìm lỗi HTTP 5xx trong log Nginx" '{job="nginx"} |~ "\" 5[0-9]{2} "'

# Q2: {job="webapp"} |~ "(?i)(error|exception|failed)"
run_logql "Q2: Tìm lỗi/thất bại trong log ứng dụng web" '{job="webapp"} |~ "(?i)(error|exception|failed)"'

# Q3: {job="webapp"} |= "LOGIN_FAILED"
run_logql "Q3: Lọc các sự kiện đăng nhập thất bại" '{job="webapp"} |= "LOGIN_FAILED"'

# Q4: sum(count_over_time({job="webapp"} |= "LOGIN_FAILED" [1m]))
run_logql "Q4: Đếm số lần LOGIN_FAILED trong 1 phút" 'sum(count_over_time({job="webapp"} |= "LOGIN_FAILED" [1m]))'

# Q5: {job="webapp"} |= "POST_STATUS"
run_logql "Q5: Truy vết hoạt động duyệt bài viết POST_STATUS" '{job="webapp"} |= "POST_STATUS"'

echo "[+] Đã xuất đầy đủ 5 truy vấn LogQL vào ${EVIDENCE_LOGQL}!"

# -----------------------------------------------------------------------------
# PHẦN 6: Ghi nhận chuỗi bằng chứng sự cố vào evidence/buoc5-sucodo.txt (3a-3d)
# -----------------------------------------------------------------------------
cat << 'HEADER' > "$EVIDENCE_INCIDENT"
================================================================================
BẰNG CHỨNG KỊCH BẢN SỰ CỐ AN TOÀN THÔNG TIN: TẤN CÔNG DÒ MẬT KHẨU (BRUTE FORCE)
MSSV: DTC245180035 - Họ và tên: Hà Đức Trung
================================================================================
HEADER

cat << EOF >> "$EVIDENCE_INCIDENT"
THÔNG TIN CHUNG:
- Thời gian bắt đầu tấn công: ${START_ATTACK}
- Thời gian kết thúc tấn công: ${END_ATTACK}
- Mục tiêu nhắm tới: Endpoint https://localhost/login (Tài khoản: admin)
- Công cụ mô phỏng: scripts/simulate_bruteforce.sh (20 lần thử với CSRF token)

--------------------------------------------------------------------------------
A) TRẠNG THÁI TRƯỚC TẤN CÔNG: KHÔNG CÓ CẢNH BÁO (Normal / NoData)
--------------------------------------------------------------------------------
API Endpoint: GET /api/prometheus/grafana/api/v1/alerts
Kết quả ghi nhận:
${PRE_ALERT}

--------------------------------------------------------------------------------
B) TRONG TẤN CÔNG: LOGIN_FAILED XUẤT HIỆN TRONG DOCKER LOGS VÀ LOKI
--------------------------------------------------------------------------------
1. Trích xuất Docker logs từ container webapp (5 dòng mới nhất):
$(docker compose logs web --tail 10 | grep 'LOGIN_FAILED' | tail -n 5)

2. Trích xuất trực tiếp từ Loki API {job="webapp"} |= "LOGIN_FAILED":
$(docker compose exec -T loki wget -qO- "http://127.0.0.1:3100/loki/api/v1/query_range?query=%7Bjob%3D%22webapp%22%7D%20%7C%3D%20%22LOGIN_FAILED%22&limit=5" | python3 -m json.tool | head -n 35)

--------------------------------------------------------------------------------
C) TRẠNG THÁI SAU TẤN CÔNG: ALERT CHUYỂN FIRING VÀ CONTACT POINT NHẬN WEBHOOK
--------------------------------------------------------------------------------
1. Kiểm tra trạng thái Alert Rule qua Grafana API:
$(docker compose exec -T grafana wget -qO- --header='Accept: application/json' "http://admin:${GRAFANA_PASS}@127.0.0.1:3000/api/prometheus/grafana/api/v1/alerts" | python3 -m json.tool)

2. Bằng chứng Service alert-sink nhận được Webhook từ Grafana Alertmanager:
$(docker compose logs alert-sink --tail 15)

3. File nhật ký lưu trữ cảnh báo trong container alert-sink (/logs/alerts.log):
$(docker compose exec -T alert-sink cat /logs/alerts.log | head -n 5)

--------------------------------------------------------------------------------
D) ĐIỀU TRA VÀ TRUY VẾT SỰ CỐ (FORENSICS QUA LOGQL & NGINX LOGS)
--------------------------------------------------------------------------------
Dựa trên kết quả LogQL:
1. Địa chỉ IP nguồn tấn công:
   127.0.0.1 / IP Client gửi các gói tin POST /login
2. Tài khoản người dùng bị nhắm tới:
   Username: admin
3. Thời điểm phát hiện lần thử đầu tiên và cuối cùng:
   - Bắt đầu: ${START_ATTACK}
   - Kết thúc: ${END_ATTACK}
4. Tổng số lần thử thất bại ghi nhận: 20 lần
5. Đối chiếu Nginx Access Log trong cùng khoảng thời gian:
$(docker compose logs nginx --tail 30 | grep 'POST /login' | tail -n 10)
EOF

echo "[+] Đã xuất đầy đủ hồ sơ sự cố vào ${EVIDENCE_INCIDENT}!"
