#!/usr/bin/env bash
set -e

cd /home/trung/blogcms
EXPORTER_PW=$(grep "^POSTGRES_EXPORTER_PASSWORD=" .env | cut -d= -f2)

if [ -z "$EXPORTER_PW" ]; then
  echo "[-] Lỗi: Không tìm thấy POSTGRES_EXPORTER_PASSWORD trong .env"
  exit 1
fi

echo "[*] Đang cấu hình tài khoản exporter trong PostgreSQL..."
docker compose exec -T db psql -U blogcms_app -d blogcms <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'exporter') THEN
    CREATE USER exporter WITH PASSWORD '${EXPORTER_PW}';
  ELSE
    ALTER USER exporter WITH PASSWORD '${EXPORTER_PW}';
  END IF;
END
\$\$;
GRANT pg_monitor TO exporter;
EOF

echo "[+] Kiểm tra phân quyền user exporter:"
docker compose exec -T db psql -U blogcms_app -d blogcms -c "\du exporter"