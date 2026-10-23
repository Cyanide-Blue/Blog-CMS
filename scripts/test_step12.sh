#!/usr/bin/env bash
set -e

BASE_URL="http://localhost:3000"
COOKIE_JAR=$(mktemp)
COOKIE_JAR_ADMIN=$(mktemp)
COOKIE_JAR_AUTH1=$(mktemp)
COOKIE_JAR_AUTH2=$(mktemp)
COOKIE_JAR_MEMBER=$(mktemp)

trap "rm -f $COOKIE_JAR $COOKIE_JAR_ADMIN $COOKIE_JAR_AUTH1 $COOKIE_JAR_AUTH2 $COOKIE_JAR_MEMBER" EXIT

echo "================================================================================"
echo "DTC245180035 - BỘ KIỂM THỬ TỰ ĐỘNG BƯỚC 1 & 2 (Blog/CMS Node.js + PostgreSQL)"
echo "Thời gian chạy: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "================================================================================"

extract_csrf() {
  local html="$1"
  local token=$(echo "$html" | grep -o 'name="_csrf" value="[^"]*"' | head -n 1 | sed 's/name="_csrf" value="//;s/"//')
  if [ -z "$token" ]; then
    token=$(echo "$html" | grep -o 'value="[^"]*" id="csrf-token-field"' | head -n 1 | sed 's/value="//;s/" id="csrf-token-field"//')
  fi
  echo "$token"
}

# ------------------------------------------------------------------------------
echo -e "\n[TEST 1] Đăng ký tài khoản mới (vai trò mặc định: member)"
# ------------------------------------------------------------------------------
REG_PAGE=$(curl -s -c "$COOKIE_JAR" "$BASE_URL/register")
CSRF_REG=$(extract_csrf "$REG_PAGE")
echo "  -> CSRF token: $CSRF_REG"

NEW_USER="newuser_$(date +%s)"
NEW_EMAIL="${NEW_USER}@test.local"
NEW_PASS="Password123!Secure"

REG_RESP=$(curl -s -i -b "$COOKIE_JAR" -c "$COOKIE_JAR" -X POST "$BASE_URL/register" \
  -d "_csrf=${CSRF_REG}" \
  -d "username=${NEW_USER}" \
  -d "email=${NEW_EMAIL}" \
  -d "full_name=Độc giả Mới" \
  -d "password=${NEW_PASS}" \
  -d "confirm_password=${NEW_PASS}")

REG_STATUS=$(echo "$REG_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> Trạng thái HTTP đăng ký: $REG_STATUS (Kỳ vọng: 302 Redirect về /?registered=1)"
if [ "$REG_STATUS" -ne 302 ]; then
  echo "[-] Đăng ký thất bại!"
  exit 1
fi
echo "[+] TEST 1 THÀNH CÔNG: Đã tạo người dùng mới '$NEW_USER'."

# ------------------------------------------------------------------------------
echo -e "\n[TEST 2] Đăng nhập & Ghi log xác thực"
# ------------------------------------------------------------------------------
echo "  2a. Đăng nhập sai mật khẩu..."
LOGIN_PAGE=$(curl -s -c "$COOKIE_JAR" "$BASE_URL/login")
CSRF_LOGIN=$(extract_csrf "$LOGIN_PAGE")

FAIL_RESP=$(curl -s -i -b "$COOKIE_JAR" -c "$COOKIE_JAR" -X POST "$BASE_URL/login" \
  -d "_csrf=${CSRF_LOGIN}" \
  -d "username=admin" \
  -d "password=SaiMatKhau123456!")

FAIL_STATUS=$(echo "$FAIL_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP Status khi sai mật khẩu: $FAIL_STATUS (Kỳ vọng: 401 Unauthorized)"
if [ "$FAIL_STATUS" -ne 401 ]; then
  echo "[-] Kỳ vọng 401 nhưng nhận $FAIL_STATUS"
  exit 1
fi
echo "[+] TEST 2a THÀNH CÔNG: Sai mật khẩu bị từ chối với 401."

echo "  2b. Đăng nhập đúng mật khẩu với tài khoản Admin..."
ADMIN_LOGIN_PAGE=$(curl -s -c "$COOKIE_JAR_ADMIN" "$BASE_URL/login")
CSRF_ADMIN_LOGIN=$(extract_csrf "$ADMIN_LOGIN_PAGE")

AUTH_RESP=$(curl -s -i -b "$COOKIE_JAR_ADMIN" -c "$COOKIE_JAR_ADMIN" -X POST "$BASE_URL/login" \
  -d "_csrf=${CSRF_ADMIN_LOGIN}" \
  -d "username=admin" \
  -d "password=123456")

AUTH_STATUS=$(echo "$AUTH_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP Status khi đúng mật khẩu: $AUTH_STATUS (Kỳ vọng: 302 Redirect)"
if [ "$AUTH_STATUS" -ne 302 ]; then
  echo "[-] Đăng nhập Admin thất bại!"
  exit 1
fi
echo "[+] TEST 2b THÀNH CÔNG: Admin đăng nhập thành công."

# Login tacgia01
A1_LOGIN_PAGE=$(curl -s -c "$COOKIE_JAR_AUTH1" "$BASE_URL/login")
CSRF_A1_LOGIN=$(extract_csrf "$A1_LOGIN_PAGE")
curl -s -b "$COOKIE_JAR_AUTH1" -c "$COOKIE_JAR_AUTH1" -X POST "$BASE_URL/login" \
  -d "_csrf=${CSRF_A1_LOGIN}" -d "username=tacgia01" -d "password=123456" > /dev/null

# Login tacgia02
A2_LOGIN_PAGE=$(curl -s -c "$COOKIE_JAR_AUTH2" "$BASE_URL/login")
CSRF_A2_LOGIN=$(extract_csrf "$A2_LOGIN_PAGE")
curl -s -b "$COOKIE_JAR_AUTH2" -c "$COOKIE_JAR_AUTH2" -X POST "$BASE_URL/login" \
  -d "_csrf=${CSRF_A2_LOGIN}" -d "username=tacgia02" -d "password=123456" > /dev/null

# Login docgia01
M1_LOGIN_PAGE=$(curl -s -c "$COOKIE_JAR_MEMBER" "$BASE_URL/login")
CSRF_M1_LOGIN=$(extract_csrf "$M1_LOGIN_PAGE")
curl -s -b "$COOKIE_JAR_MEMBER" -c "$COOKIE_JAR_MEMBER" -X POST "$BASE_URL/login" \
  -d "_csrf=${CSRF_M1_LOGIN}" -d "username=docgia01" -d "password=123456" > /dev/null

# ------------------------------------------------------------------------------
echo -e "\n[TEST 3] Độc giả bình luận & Anti-Spam Rate Limiting (> 5 bình luận/phút)"
# ------------------------------------------------------------------------------
POST_PAGE=$(curl -s -b "$COOKIE_JAR_MEMBER" "$BASE_URL/posts/kien-truc-microservices-voi-docker-va-nodejs")
CSRF_COMMENT=$(extract_csrf "$POST_PAGE")

echo "  3a. Gửi bình luận hợp lệ..."
COMMENT_RESP=$(curl -s -i -b "$COOKIE_JAR_MEMBER" -c "$COOKIE_JAR_MEMBER" -X POST "$BASE_URL/comments" \
  -d "_csrf=${CSRF_COMMENT}" \
  -d "post_id=1" \
  -d "return_slug=kien-truc-microservices-voi-docker-va-nodejs" \
  -d "content=Kiểm thử bình luận tự động từ docgia01 thành công.")

C_STATUS=$(echo "$COMMENT_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status gửi bình luận: $C_STATUS (Kỳ vọng: 302 Redirect)"
if [ "$C_STATUS" -ne 302 ]; then
  echo "[-] Gửi bình luận thất bại!"
  exit 1
fi
echo "[+] TEST 3a THÀNH CÔNG: Bình luận được đăng."

echo "  3b. Kiểm tra Anti-Spam (gửi liên tiếp 5 bình luận để kích hoạt chặn)..."
for i in {1..5}; do
  curl -s -b "$COOKIE_JAR_MEMBER" -c "$COOKIE_JAR_MEMBER" -X POST "$BASE_URL/comments" \
    -d "_csrf=${CSRF_COMMENT}" \
    -d "post_id=1" \
    -d "return_slug=kien-truc-microservices-voi-docker-va-nodejs" \
    -d "content=Spam comment test $i" > /dev/null
done

# Bình luận thứ 6 phải bị chặn 429
SPAM_RESP=$(curl -s -i -b "$COOKIE_JAR_MEMBER" -c "$COOKIE_JAR_MEMBER" -X POST "$BASE_URL/comments" \
  -H "Accept: application/json" \
  -d "_csrf=${CSRF_COMMENT}" \
  -d "post_id=1" \
  -d "return_slug=kien-truc-microservices-voi-docker-va-nodejs" \
  -d "content=Spam comment 6 trigger rate limit")

SPAM_STATUS=$(echo "$SPAM_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status khi spam vượt ngưỡng: $SPAM_STATUS (Kỳ vọng: 429 Too Many Requests)"
if [ "$SPAM_STATUS" -ne 429 ]; then
  echo "[-] Anti-spam rate limiting chưa chặn đúng!"
  exit 1
fi
echo "[+] TEST 3b THÀNH CÔNG: Chặn spam rate limit 429 hoạt động chính xác."

# ------------------------------------------------------------------------------
echo -e "\n[TEST 4] Tác giả tạo bài, chặn tự ý publish, và gửi duyệt (pending)"
# ------------------------------------------------------------------------------
AUTHOR_PAGE=$(curl -s -b "$COOKIE_JAR_AUTH1" "$BASE_URL/author/posts/new")
CSRF_AUTH=$(extract_csrf "$AUTHOR_PAGE")

echo "  4a. Thử tự ý xuất bản (publish_direct) bằng tài khoản Tác giả..."
HACK_PUBLISH=$(curl -s -i -b "$COOKIE_JAR_AUTH1" -c "$COOKIE_JAR_AUTH1" -X POST "$BASE_URL/author/posts/save?_csrf=${CSRF_AUTH}" \
  -H "Accept: application/json" \
  -F "_csrf=${CSRF_AUTH}" \
  -F "title=Bai Viet Hack Publish" \
  -F "category_id=1" \
  -F "excerpt=Tom tat" \
  -F "content=Noi dung" \
  -F "action=publish_direct")

HACK_STATUS=$(echo "$HACK_PUBLISH" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status khi tác giả cố tình publish: $HACK_STATUS (Kỳ vọng: 403 Forbidden)"
if [ "$HACK_STATUS" -ne 403 ]; then
  echo "[-] Tác giả không bị chặn khi tự publish!"
  exit 1
fi
echo "[+] TEST 4a THÀNH CÔNG: Tác giả bị chặn 403 khi tự ý xuất bản."

echo "  4b. Tác giả tạo bài viết mới và gửi duyệt (pending)..."
CREATE_RESP=$(curl -s -i -b "$COOKIE_JAR_AUTH1" -c "$COOKIE_JAR_AUTH1" -X POST "$BASE_URL/author/posts/save?_csrf=${CSRF_AUTH}" \
  -F "_csrf=${CSRF_AUTH}" \
  -F "title=Kiểm Thử Bài Viết Tác Giả 01 Chờ Duyệt" \
  -F "category_id=1" \
  -F "tags=testing, devops" \
  -F "excerpt=Bài viết kiểm thử quy trình phê duyệt" \
  -F "content=## Nội dung kiểm thử\nQuy trình phê duyệt bài viết." \
  -F "action=submit_pending")

CREATE_STATUS=$(echo "$CREATE_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status khi tạo bài gửi duyệt: $CREATE_STATUS (Kỳ vọng: 302 Redirect)"
if [ "$CREATE_STATUS" -ne 302 ]; then
  echo "[-] Tạo bài gửi duyệt thất bại!"
  exit 1
fi
echo "[+] TEST 4b THÀNH CÔNG: Bài viết được tạo ở trạng thái pending."

# ------------------------------------------------------------------------------
echo -e "\n[TEST 5] Quản trị viên duyệt bài (xuất bản & từ chối kèm lý do)"
# ------------------------------------------------------------------------------
# Lấy ID bài viết pending vừa tạo
PENDING_ID=$(docker compose exec -T db psql -U blogcms_app -d blogcms -t -A -c "SELECT id FROM posts WHERE status='pending' AND title LIKE '%Tác Giả 01%' LIMIT 1")
echo "  -> ID bài viết pending: $PENDING_ID"

QUEUE_PAGE=$(curl -s -b "$COOKIE_JAR_ADMIN" "$BASE_URL/admin/queue?status=pending")
CSRF_ADMIN=$(extract_csrf "$QUEUE_PAGE")

echo "  5a. Admin phê duyệt và xuất bản bài viết..."
PUB_RESP=$(curl -s -i -b "$COOKIE_JAR_ADMIN" -c "$COOKIE_JAR_ADMIN" -X POST "$BASE_URL/admin/posts/${PENDING_ID}/status" \
  -d "_csrf=${CSRF_ADMIN}" \
  -d "action=publish")

PUB_STATUS=$(echo "$PUB_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status khi admin duyệt: $PUB_STATUS (Kỳ vọng: 302 Redirect)"

# Kiểm tra bài xuất hiện trong RSS
RSS_CONTENT=$(curl -s "$BASE_URL/rss.xml")
if echo "$RSS_CONTENT" | grep -q "Kiểm Thử Bài Viết Tác Giả 01"; then
  echo "  -> Đã tìm thấy bài viết trong /rss.xml!"
else
  echo "[-] Bài viết không xuất hiện trong RSS!"
  exit 1
fi
echo "[+] TEST 5a THÀNH CÔNG: Bài viết được xuất bản và đồng bộ vào /rss.xml."

echo "  5b. Tác giả 2 gửi bài và Admin từ chối kèm lý do phản hồi..."
AUTH2_PAGE=$(curl -s -b "$COOKIE_JAR_AUTH2" "$BASE_URL/author/posts/new")
CSRF_AUTH2=$(extract_csrf "$AUTH2_PAGE")

curl -s -b "$COOKIE_JAR_AUTH2" -c "$COOKIE_JAR_AUTH2" -X POST "$BASE_URL/author/posts/save?_csrf=${CSRF_AUTH2}" \
  -F "_csrf=${CSRF_AUTH2}" \
  -F "title=Bài Viết Tác Giả 02 Cần Từ Chối" \
  -F "category_id=2" \
  -F "excerpt=Bài viết này sẽ bị admin từ chối" \
  -F "content=Nội dung thiếu dẫn chứng" \
  -F "action=submit_pending" > /dev/null

REJECT_ID=$(docker compose exec -T db psql -U blogcms_app -d blogcms -t -A -c "SELECT id FROM posts WHERE status='pending' AND title LIKE '%Tác Giả 02%' LIMIT 1")
echo "  -> ID bài viết bị từ chối: $REJECT_ID"

QUEUE_PAGE2=$(curl -s -b "$COOKIE_JAR_ADMIN" "$BASE_URL/admin/queue?status=pending")
CSRF_ADMIN2=$(extract_csrf "$QUEUE_PAGE2")

REJ_RESP=$(curl -s -i -b "$COOKIE_JAR_ADMIN" -c "$COOKIE_JAR_ADMIN" -X POST "$BASE_URL/admin/posts/${REJECT_ID}/status" \
  -d "_csrf=${CSRF_ADMIN2}" \
  -d "action=reject" \
  -d "review_note=Bài viết thiếu nguồn dẫn chứng")

REJ_STATUS=$(echo "$REJ_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status khi admin từ chối: $REJ_STATUS (Kỳ vọng: 302 Redirect)"

# Tác giả 2 kiểm tra dashboard thấy lý do
DASH2_CONTENT=$(curl -s -b "$COOKIE_JAR_AUTH2" "$BASE_URL/author/dashboard?status=rejected")
if echo "$DASH2_CONTENT" | grep -q "Bài viết thiếu nguồn dẫn chứng"; then
  echo "  -> Tác giả 2 đã thấy ghi chú từ chối trên Dashboard!"
else
  echo "[-] Tác giả không thấy ghi chú từ chối!"
  exit 1
fi
echo "[+] TEST 5b THÀNH CÔNG: Quy trình từ chối bài viết kèm lý do hoạt động chuẩn."

# ------------------------------------------------------------------------------
echo -e "\n[TEST 6] Kiểm tra Phân quyền (RBAC)"
# ------------------------------------------------------------------------------
echo "  6a. Tác giả 1 cố sửa bài viết của Tác giả 2..."
CROSS_RESP=$(curl -s -i -b "$COOKIE_JAR_AUTH1" "$BASE_URL/author/posts/${REJECT_ID}/edit")
CROSS_STATUS=$(echo "$CROSS_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status truy cập sửa bài tác giả khác: $CROSS_STATUS (Kỳ vọng: 403 Forbidden)"
if [ "$CROSS_STATUS" -ne 403 ]; then
  echo "[-] Cross-author edit không bị chặn!"
  exit 1
fi

echo "  6b. Độc giả cố vào /author/dashboard hoặc /admin/dashboard..."
MEMBER_AUTH_RESP=$(curl -s -i -b "$COOKIE_JAR_MEMBER" "$BASE_URL/author/dashboard")
MEMBER_STATUS=$(echo "$MEMBER_AUTH_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status khi member vào /author/dashboard: $MEMBER_STATUS (Kỳ vọng: 403 Forbidden)"
if [ "$MEMBER_STATUS" -ne 403 ]; then
  echo "[-] Member vào author không bị chặn 403!"
  exit 1
fi

MEMBER_ADMIN_RESP=$(curl -s -i -b "$COOKIE_JAR_MEMBER" "$BASE_URL/admin/dashboard")
MEMBER_ADM_STATUS=$(echo "$MEMBER_ADMIN_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status khi member vào /admin/dashboard: $MEMBER_ADM_STATUS (Kỳ vọng: 403 Forbidden)"
if [ "$MEMBER_ADM_STATUS" -ne 403 ]; then
  echo "[-] Member vào admin không bị chặn 403!"
  exit 1
fi
echo "[+] TEST 6 THÀNH CÔNG: Cơ chế phân quyền RBAC hoạt động chuẩn xác."

# ------------------------------------------------------------------------------
echo -e "\n[TEST 7] Kiểm tra An toàn: Chống XSS & Kiểm tra Magic Bytes Upload"
# ------------------------------------------------------------------------------
echo "  7a. Kiểm tra Sanitization XSS trong Markdown..."
PREVIEW_RESP=$(curl -s -b "$COOKIE_JAR_AUTH1" -X POST "$BASE_URL/author/posts/preview" \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: ${CSRF_A1_LOGIN}" \
  -d '{"content": "# Heading\n<script>alert(1)</script>\n<img src=x onerror=alert(1)>\n[Click me](javascript:alert(1))"}')

echo "  -> Output render HTML: $PREVIEW_RESP"
if echo "$PREVIEW_RESP" | grep -E '<script|<img|href="javascript:'; then
  echo "[-] XSS không bị loại bỏ!"
  exit 1
fi
echo "[+] TEST 7a THÀNH CÔNG: XSS payload bị loại bỏ hoàn toàn."

echo "  7b. Thử upload tệp giả mạo (.jpg nhưng nội dung là script shell)..."
FAKE_FILE=$(mktemp --suffix=.jpg)
echo "<?php echo 'malicious shell'; ?>" > "$FAKE_FILE"

UPLOAD_RESP=$(curl -s -i -b "$COOKIE_JAR_AUTH1" -X POST "$BASE_URL/author/posts/save?_csrf=${CSRF_A1_LOGIN}" \
  -F "_csrf=${CSRF_A1_LOGIN}" \
  -F "title=Bai Viet Test Upload Fake" \
  -F "category_id=1" \
  -F "content=Test" \
  -F "action=save_draft" \
  -F "cover_image=@${FAKE_FILE};type=image/jpeg")

rm -f "$FAKE_FILE"
UPLOAD_STATUS=$(echo "$UPLOAD_RESP" | grep -E '^HTTP' | tail -n 1 | awk '{print $2}')
echo "  -> HTTP status khi upload fake image: $UPLOAD_STATUS (Kỳ vọng: 400 Bad Request)"
if [ "$UPLOAD_STATUS" -ne 400 ]; then
  echo "[-] Fake upload không bị chặn với 400!"
  exit 1
fi
echo "[+] TEST 7b THÀNH CÔNG: Chữ ký nhị phân Magic Bytes chặn tệp độc hại."

echo -e "\n================================================================================"
echo "TẤT CẢ 7 KỊCH BẢN KIỂM THỬ ĐÃ VƯỢT QUA 100%!"
echo "================================================================================"