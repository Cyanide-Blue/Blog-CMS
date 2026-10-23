#!/usr/bin/env bash
set -e

EVIDENCE_FILE="/home/trung/blogcms/evidence/buoc4-giamsat.txt"
BASE_HTTPS="https://localhost"

cd /home/trung/blogcms
GRAFANA_PW=$(grep "^GRAFANA_ADMIN_PASSWORD=" .env | cut -d= -f2)

echo "================================================================================" | tee "$EVIDENCE_FILE"
echo "BẰNG CHỨNG KIỂM TRA BƯỚC 4: PROMETHEUS + GRAFANA + EXPORTERS GIÁM SÁT HỆ THỐNG" | tee -a "$EVIDENCE_FILE"
echo "MSSV: DTC245180035 - Họ và tên: Hà Đức Trung" | tee -a "$EVIDENCE_FILE"
echo "Thời gian ghi nhận: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" | tee -a "$EVIDENCE_FILE"
echo "================================================================================" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "1. SINH TẢI HỆ THỐNG (200 REQUESTS QUA HTTPS ĐỂ TẠO SỐ LIỆU DASHBOARDS)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "[*] Đang gửi 200 requests vào các trang chủ, danh sách, chi tiết, tìm kiếm và RSS..."
for i in $(seq 1 40); do
  curl -sk "$BASE_HTTPS/" > /dev/null
  curl -sk "$BASE_HTTPS/posts" > /dev/null
  curl -sk "$BASE_HTTPS/posts?q=docker" > /dev/null
  curl -sk "$BASE_HTTPS/posts/kien-truc-microservices-voi-docker-va-nodejs" > /dev/null
  curl -sk "$BASE_HTTPS/rss.xml" > /dev/null
done
echo "[+] Đã hoàn thành 200 requests sinh tải thành công!" | tee -a "$EVIDENCE_FILE"

# Chờ 15s để Prometheus hoàn thành 1 chu kỳ scrape_interval
echo "[*] Chờ 15s để Prometheus hoàn thành chu kỳ scrape_interval..."
sleep 15

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "2. TRẠNG THÁI TOÀN BỘ CÁC SERVICE TRONG STACK (docker compose ps)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
docker compose ps | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "3. KIỂM TRA API PROMETHEUS TARGETS (/api/v1/targets - KỲ VỌNG: TẤT CẢ TARGET UP)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
TARGETS_JSON=$(docker compose exec -T prometheus wget -qO- http://localhost:9090/api/v1/targets)
echo "$TARGETS_JSON" | python3 -c '
import sys, json
data = json.load(sys.stdin)
active_targets = data.get("data", {}).get("activeTargets", [])
print(f"Tổng số targets đang theo dõi: {len(active_targets)}")
for t in active_targets:
    labels = t.get("labels", {})
    job = labels.get("job", "unknown")
    instance = labels.get("instance", "unknown")
    health = t.get("health", "unknown")
    last_scrape = t.get("lastScrape", "unknown")
    print(f"  - Job: {job:<15} Instance: {instance:<25} Health: {health} (Last scrape: {last_scrape})")
' | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "4. KIỂM TRA DỮ LIỆU PROMQL TRUY VẤN THỰC TẾ QUA PROMETHEUS API" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"

echo "-> Truy vấn 1: container_memory_usage_bytes (Bộ nhớ RAM theo cgroups):" | tee -a "$EVIDENCE_FILE"
docker compose exec -T prometheus wget -qO- 'http://localhost:9090/api/v1/query?query=container_memory_usage_bytes' | python3 -c '
import sys, json
data = json.load(sys.stdin)
results = data.get("data", {}).get("result", [])
print(f"  Số metric cgroups RAM trả về: {len(results)}")
for r in results:
    metric = r.get("metric", {})
    cgroup_id = metric.get("id", "root")
    val = float(r.get("value", [0, 0])[1]) / (1024 * 1024)
    print(f"    * Cgroup [{cgroup_id}]: {val:.2f} MB")
' | tee -a "$EVIDENCE_FILE"

echo -e "\n-> Truy vấn 2: nginx_connections_active (Kết nối Nginx đang hoạt động):" | tee -a "$EVIDENCE_FILE"
docker compose exec -T prometheus wget -qO- 'http://localhost:9090/api/v1/query?query=nginx_connections_active' | python3 -c '
import sys, json
data = json.load(sys.stdin)
results = data.get("data", {}).get("result", [])
for r in results:
    val = r.get("value", [0, 0])[1]
    print(f"    * nginx_connections_active = {val}")
' | tee -a "$EVIDENCE_FILE"

echo -e "\n-> Truy vấn 3: pg_stat_database_numbackends (Số kết nối vào database blogcms):" | tee -a "$EVIDENCE_FILE"
docker compose exec -T prometheus wget -qO- 'http://localhost:9090/api/v1/query?query=pg_stat_database_numbackends%7Bdatname="blogcms"%7D' | python3 -c '
import sys, json
data = json.load(sys.stdin)
results = data.get("data", {}).get("result", [])
for r in results:
    val = r.get("value", [0, 0])[1]
    print(f"    * pg_stat_database_numbackends(blogcms) = {val}")
' | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "5. KIỂM TRA TRUY CẬP GRAFANA QUA HTTPS NGINX (curl -kI https://localhost/grafana/login)" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
curl -skI "$BASE_HTTPS/grafana/login" | tee -a "$EVIDENCE_FILE"

echo -e "\n--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "6. KIỂM TRA PROVISIONING DATASOURCE VÀ DASHBOARDS QUA GRAFANA API" | tee -a "$EVIDENCE_FILE"
echo "--------------------------------------------------------------------------------" | tee -a "$EVIDENCE_FILE"
echo "-> Danh sách Datasource:" | tee -a "$EVIDENCE_FILE"
curl -sk -u "admin:${GRAFANA_PW}" "$BASE_HTTPS/grafana/api/datasources" | python3 -c '
import sys, json
sources = json.load(sys.stdin)
for s in sources:
    name = s.get("name")
    typ = s.get("type")
    url = s.get("url")
    is_def = s.get("isDefault")
    print(f"  * Datasource: {name} (Type: {typ}, URL: {url}, Default: {is_def})")
' | tee -a "$EVIDENCE_FILE"

echo -e "\n-> Danh sách Dashboards trong thư mục \"BlogCMS Monitoring\":" | tee -a "$EVIDENCE_FILE"
curl -sk -u "admin:${GRAFANA_PW}" "$BASE_HTTPS/grafana/api/search" | python3 -c '
import sys, json
items = json.load(sys.stdin)
for it in items:
    if it.get("type") == "dash-db":
        title = it.get("title")
        folder = it.get("folderTitle")
        uid = it.get("uid")
        url = it.get("url")
        print(f"  * Dashboard: \"{title}\" (Folder: \"{folder}\", UID: {uid}, URL: {url})")
' | tee -a "$EVIDENCE_FILE"

echo -e "\n================================================================================" | tee -a "$EVIDENCE_FILE"
echo "HOÀN THÀNH TẤT CẢ KIỂM TRA BƯỚC 4!" | tee -a "$EVIDENCE_FILE"
echo "File lưu trữ: $EVIDENCE_FILE" | tee -a "$EVIDENCE_FILE"
echo "================================================================================" | tee -a "$EVIDENCE_FILE"