#!/usr/bin/env bash
# ==============================================================================
# Script sinh chứng chỉ SSL/TLS tự ký cho Nginx Reverse Proxy
# MSSV: DTC245180035 - Hà Đức Trung
# Sử dụng: ./nginx/gen-cert.sh [LAN_IP_TUY_CHON]
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/certs"
mkdir -p "${CERTS_DIR}"

KEY_FILE="${CERTS_DIR}/server.key"
CRT_FILE="${CERTS_DIR}/server.crt"
CONF_FILE="${CERTS_DIR}/openssl.cnf"

LAN_IP="$1"
SAN="DNS:localhost,IP:127.0.0.1"

if [ -n "$LAN_IP" ]; then
  SAN="${SAN},IP:${LAN_IP}"
  echo "[+] Thêm IP LAN phụ vào SAN: ${LAN_IP}"
fi

echo "[*] Đang tạo cấu hình OpenSSL SAN: ${SAN}..."
cat <<EOF > "${CONF_FILE}"
[req]
default_bits        = 2048
prompt              = no
default_md          = sha256
distinguished_name  = req_distinguished_name
req_extensions      = req_ext
x509_extensions     = v3_req

[req_distinguished_name]
C  = VN
ST = Hanoi
L  = Hanoi
O  = BlogCMS-DevOps
OU = DTC245180035
CN = localhost

[req_ext]
subjectAltName = ${SAN}

[v3_req]
subjectAltName = ${SAN}
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF

echo "[*] Đang sinh RSA Private Key (2048-bit) và Certificate (365 ngày)..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "${KEY_FILE}" \
  -out "${CRT_FILE}" \
  -config "${CONF_FILE}"

chmod 600 "${KEY_FILE}"
chmod 644 "${CRT_FILE}"
rm -f "${CONF_FILE}"

echo "[+] Đã sinh chứng chỉ SSL/TLS thành công:"
echo "    - Private Key: ${KEY_FILE}"
echo "    - Certificate: ${CRT_FILE}"
echo "    - Hiệu lực:    365 ngày"
echo "    - SAN:         ${SAN}"

echo -e "\n[*] Thông tin chi tiết chứng chỉ:"
openssl x509 -in "${CRT_FILE}" -noout -subject -dates -ext subjectAltName