#!/usr/bin/env bash
set -e

EVIDENCE_FILE="/home/trung/blogcms/evidence/buoc12-web-db.txt"
cd /home/trung/blogcms

echo "================================================================================" | tee "$EVIDENCE_FILE"
echo "BẰNG CHỨNG TRIỂN KHAI BƯỚC 1 & 2 - BLOG/CMS NODE.JS + POSTGRESQL + PGADMIN" | tee -a "$EVIDENCE_FILE"
echo "MSSV: DTC245180035 - Họ và tên: Hà Đức Trung" | tee -a "$EVIDENCE_FILE"
echo "Thời gian ghi nhận: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" | tee -a "$EVIDENCE_FILE"
echo "================================================================================" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "1. DOCKER COMPOSE PS (TẤT CẢ SERVICE HEALTHY / RUNNING)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
docker compose ps | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "2. DOCKER COMPOSE LOGS DB --TAIL=30" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
docker compose logs db --tail=30 | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "3. DOCKER COMPOSE LOGS WEB --TAIL=50 (LOGS CẤU TRÚC AUTH_OK, AUTH_FAIL, POST_STATUS)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
docker compose logs web --tail=50 | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "4. DOCKER COMPOSE EXEC DB PSQL -U blogcms_app -d blogcms -c '\dt' (7 BẢNG CƠ SỞ DỮ LIỆU)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
docker compose exec -T db psql -U blogcms_app -d blogcms -c '\dt' | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "5. SỐ LƯỢNG BÀI VIẾT ĐÃ XUẤT BẢN (STATUS = 'published')" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
docker compose exec -T db psql -U blogcms_app -d blogcms -c "SELECT count(*) AS published_posts FROM posts WHERE status = 'published';" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "6. HEALTHCHECK HTTP ENDPOINT (curl -sI http://localhost:3000/health)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
curl -sI http://localhost:3000/health | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "7. RSS FEED HTTP ENDPOINT (curl -sI http://localhost:3000/rss.xml)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
curl -sI http://localhost:3000/rss.xml | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "8. KẾT QUẢ KỊCH BẢN KIỂM THỬ TỰ ĐỘNG TOÀN DIỆN (bash scripts/test_step12.sh)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
bash /home/trung/blogcms/scripts/test_step12.sh | tee -a "$EVIDENCE_FILE"

echo -e "\n================================================================================" | tee -a "$EVIDENCE_FILE"
echo "HOÀN TẤT THU THẬP BẰNG CHỨNG BƯỚC 1 & 2!" | tee -a "$EVIDENCE_FILE"
echo "File lưu trữ: $EVIDENCE_FILE" | tee -a "$EVIDENCE_FILE"
echo "================================================================================" | tee -a "$EVIDENCE_FILE"