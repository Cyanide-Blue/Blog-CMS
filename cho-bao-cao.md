# TÀI LIỆU TỔNG HỢP PHỤC VỤ VIẾT BÁO CÁO BÀI TẬP LỚN
## ĐỀ TÀI: TRIỂN KHAI VÀ QUẢN TRỊ HỆ THỐNG PHẦN MỀM BLOG/CMS TRÊN DOCKER

- **Học viên thực hiện**: Hà Đức Trung
- **Mã số sinh viên (MSSV)**: DTC245180035
- **Môn học**: Triển khai và Quản trị Hệ thống Phần mềm (DevOps)
- **Môi trường thực nghiệm**: Docker Desktop 4.30+ (WSL2 Ubuntu 22.04 LTS), Windows 11 Host
- **Kho mã nguồn (GitHub)**: `DTC245180035-blogcms-devops`

---

## BẢNG TỔNG HỢP THÀNH PHẦN - PHIÊN BẢN VÀ THÔNG SỐ THỰC TẾ

| STT | Thành phần dịch vụ | Service Compose | Image Base & Tag cố định | User thực thi | Filesystem | Giới hạn CPU / RAM |
|---|---|---|---|---|---|---|
| 1 | Nginx Reverse Proxy | `nginx` | `nginxinc/nginx-unprivileged:1.27-alpine` | `101:101` (nginx) | Read-only | 0.5 CPU / 256MB |
| 2 | Web Blog/CMS App | `web` | `node:20.14.0-alpine3.20` | `1000:1000` (node) | Read-only | 1.0 CPU / 512MB |
| 3 | Cơ sở dữ liệu | `db` | `postgres:16.3-alpine3.20` | `70:70` (postgres) | Writable Volume | 1.0 CPU / 512MB |
| 4 | Quản trị CSDL Web | `pgadmin` | `dpage/pgadmin4:8.8` | `5050:5050` (pgadmin) | Writable Volume | 0.5 CPU / 512MB |
| 5 | Thu thập Metrics | `prometheus` | `prom/prometheus:v2.52.0` | `65534:65534` (nobody) | Read-only | 0.5 CPU / 512MB |
| 6 | Trực quan hóa Dashboard | `grafana` | `grafana/grafana:11.0.0` | `472:472` (grafana) | Read-only | 0.5 CPU / 512MB |
| 7 | Giám sát Container | `cadvisor` | `gcr.io/cadvisor/cadvisor:v0.49.1` | Root (Mount Socket) | Host read-only | 0.5 CPU / 256MB |
| 8 | Thu thập Metrics Nginx | `nginx-exporter` | `nginx/nginx-prometheus-exporter:1.2.0` | `65534:65534` (nobody) | Read-only | 0.2 CPU / 64MB |
| 9 | Thu thập Metrics Postgres| `postgres-exporter`| `prometheuscommunity/postgres-exporter:v0.15.0`| `65534:65534` (nobody) | Read-only | 0.2 CPU / 64MB |
| 10 | Tổng hợp Log tập trung | `loki` | `grafana/loki:3.0.0` | `10001:10001` (loki) | Read-only | 0.5 CPU / 512MB |
| 11 | Thu thập Log Container | `promtail` | `grafana/promtail:3.0.0` | Root (Mount Socket) | Read-only | 0.5 CPU / 256MB |
| 12 | Tiếp nhận Webhook Alert| `alert-sink` | `python:3.11-alpine` | `10001:10001` (appuser)| Read-only | 0.5 CPU / 128MB |

### Số liệu Thực tế từ Kho Git (3 Commits Chuẩn)
1. **COMMIT 1 (`7f236c7`)**: `feat: Khởi tạo ứng dụng web Blog/CMS, CSDL PostgreSQL và Nginx Reverse Proxy với HTTPS` (76 tệp, +7,379 dòng).
2. **COMMIT 2 (`4c07cb1`)**: `feat: Tích hợp hệ thống giám sát Prometheus và Grafana cùng các Exporter` (13 tệp, +788 dòng, -18 dòng).
3. **COMMIT 3 (`faaf4dd`)**: `feat: Tích hợp ghi log tập trung Loki, cảnh báo an ninh và triển khai các biện pháp Hardening toàn diện` (22 tệp, +1,431 dòng, -150 dòng).

---

## CHƯƠNG 1: TỔNG QUAN HỆ THỐNG VÀ THIẾT KẾ KIẾN TRÚC

### 1. Mô tả Thực tế
Hệ thống Blog/CMS được thiết kế theo kiến trúc Microservices hiện đại, đóng gói toàn bộ 12 dịch vụ trong Docker containers và quản trị tập trung thông qua Docker Compose v2. Hệ thống áp dụng triệt để nguyên lý "Phòng thủ theo chiều sâu" (Defense-in-Depth) với việc phân tách mạng thành 3 phân vùng bridge độc lập: `blogcms_frontend` (giao tiếp bên ngoài), `blogcms_backend` (cô lập CSDL mức `internal: true`), và `blogcms_monitoring` (hạ tầng giám sát số liệu và nhật ký).

### 2. Đường dẫn File Cấu hình Trọng tâm
- [`docker-compose.yml`](file:///home/trung/blogcms/docker-compose.yml): Tệp điều phối toàn bộ 12 containers, 3 networks, 7 volumes và các chính sách bảo mật, phân bổ tài nguyên.
- [`.env.example`](file:///home/trung/blogcms/.env.example): Mẫu biến môi trường tiêu chuẩn hóa, không chứa thông tin bí mật.
- [`.gitignore`](file:///home/trung/blogcms/.gitignore): Danh sách loại trừ an toàn loại bỏ `.env`, khóa bí mật SSL/TLS, thư mục `node_modules` và file bằng chứng tạm.

### 3. File Bằng chứng Tương ứng
- `evidence/buoc0-moitruong.txt`: Ghi nhận phiên bản Docker, Docker Compose, hạt nhân Linux WSL2, CPU và RAM máy chủ.

### 4. Danh sách Ảnh cần Chụp & Lệnh Thực thi
- **Ảnh 1.1**: Cấu trúc thư mục dự án và trạng thái Git sạch sẽ.
  - *Lệnh*: `git status && tree -L 2 -I 'node_modules|certs'`
- **Ảnh 1.2**: Trạng thái 12/12 container hoạt động đồng thời và healthy.
  - *Lệnh*: `docker compose ps`
- **Ảnh 1.3**: Danh sách các Docker Networks phân tách.
  - *Lệnh*: `docker network ls | grep blogcms`

---

## CHƯƠNG 2: PHÁT TRIỂN ỨNG DỤNG WEB BLOG/CMS VÀ CSDL POSTGRESQL

### 1. Mô tả Thực tế
Ứng dụng Blog/CMS xây dựng trên nền Node.js 20 Express với template engine EJS, tích hợp xác thực Session lưu trữ bảo mật và phân quyền vai trò (RBAC) 3 cấp độ:
- **Member (Độc giả)**: Đăng ký tài khoản, xem bài viết theo danh mục/thẻ, gửi bình luận (có cơ chế giới hạn tần suất 5 bình luận/phút).
- **Author (Tác giả)**: Soạn thảo bài viết định dạng Markdown, tải ảnh bìa có kiểm tra chữ ký nhị phân (Magic Bytes), gửi bài vào hàng đợi duyệt (`pending`). Tác giả bị chặn 403 nếu cố tình tự ý xuất bản (`publish_direct`).
- **Admin (Quản trị viên)**: Xem hàng đợi duyệt bài, xuất bản bài viết (`published`), từ chối bài viết (`rejected`) bắt buộc ghi rõ lý do phản hồi, quản lý danh mục, người dùng và bình luận.

Hệ thống CSDL PostgreSQL 16 được thiết kế chuẩn hóa với 7 bảng quan hệ (`users`, `categories`, `tags`, `posts`, `post_tags`, `comments`, `media`), cài đặt toàn vẹn dữ liệu qua khóa ngoại CASCADE/RESTRICT và được khởi tạo tự động 12 bài viết mẫu cùng 5 tài khoản thử nghiệm qua `db/init.sql`.

### 2. Đường dẫn File Cấu hình Trọng tâm
- [`db/init.sql`](file:///home/trung/blogcms/db/init.sql): Kịch bản DDL khởi tạo schema và seed dữ liệu.
- [`web/src/middleware/auth.js`](file:///home/trung/blogcms/web/src/middleware/auth.js): Middleware kiểm tra phiên, xác thực CSRF và phân quyền RBAC.
- [`web/src/middleware/upload.js`](file:///home/trung/blogcms/web/src/middleware/upload.js): Xử lý tải ảnh an toàn, kiểm tra MIME type và magic bytes (PNG, JPEG, WEBP, GIF).
- [`web/src/controllers/authorController.js`](file:///home/trung/blogcms/web/src/controllers/authorController.js): Điều khiển nghiệp vụ soạn thảo, lưu nháp, gửi duyệt bài viết.
- [`web/src/controllers/adminController.js`](file:///home/trung/blogcms/web/src/controllers/adminController.js): Điều khiển hàng đợi phê duyệt, xuất bản và từ chối bài viết.

### 3. File Bằng chứng Tương ứng
- `evidence/buoc12-web-db.txt`: Toàn bộ 7 kịch bản kiểm thử tự động đăng ký, đăng nhập, phân quyền RBAC, kiểm duyệt bài, chống spam, upload magic bytes và nguồn cấp RSS.

### 4. Danh sách Ảnh cần Chụp & Lệnh Thực thi
- **Ảnh 2.1**: Giao diện Trang chủ Blog (`https://localhost`).
  - *Mở trình duyệt*: `https://localhost`
- **Ảnh 2.2**: Giao diện Bàn làm việc Tác giả soạn thảo Markdown (`/author/dashboard`).
  - *Mở trình duyệt*: `https://localhost/login` (user `tacgia01`) -> vào `/author/dashboard`
- **Ảnh 2.3**: Giao diện Hàng đợi duyệt bài của Quản trị viên (`/admin/queue`).
  - *Mở trình duyệt*: `https://localhost/login` (user `admin`) -> vào `/admin/queue`
- **Ảnh 2.4**: Nguồn cấp dữ liệu chuẩn XML RSS Feed (`/rss.xml`).
  - *Mở trình duyệt*: `https://localhost/rss.xml`

---

## CHƯƠNG 3: REVERSE PROXY NGINX, HTTPS TỰ KÝ VÀ SECURITY HEADERS

### 1. Mô tả Thực tế
Nginx Reverse Proxy được cấu hình làm cổng tiếp nhận duy nhất cho toàn bộ hệ thống trên cổng 80 (HTTP) và 443 (HTTPS):
- Tự động chuyển hướng vĩnh viễn (301 Permanent Redirect) toàn bộ lưu lượng HTTP sang HTTPS.
- Cấu hình TLS v1.2 và TLS v1.3 với bộ Cipher Suite mạnh mẽ (`ECDHE-ECDSA-AES128-GCM-SHA256:...`), vô hiệu hóa TLS v1.0/v1.1 cũ và yếu.
- Chứng chỉ SSL/TLS tự ký được tạo tự động qua OpenSSL với RSA 2048-bit, thời hạn 365 ngày kèm SAN (`DNS:localhost`, `IP:127.0.0.1`).
- Thiết lập nghiêm ngặt các Security Headers có cờ `always`: `Content-Security-Policy`, `Strict-Transport-Security` (HSTS), `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`.
- Cấu hình định tuyến proxy cho ứng dụng web chính (`/`), CSDL pgAdmin (`/pgadmin/`) và giao diện giám sát Grafana (`/grafana/`).
- Ẩn hoàn toàn phiên bản máy chủ (`server_tokens off;`) và ẩn header công nghệ nguồn (`proxy_hide_header X-Powered-By;`).

### 2. Đường dẫn File Cấu hình Trọng tâm
- [`nginx/nginx.conf`](file:///home/trung/blogcms/nginx/nginx.conf): Cấu hình đầy đủ các khối HTTP/HTTPS, SSL termination, proxy passing, rate limiting và security headers.
- [`nginx/gen-cert.sh`](file:///home/trung/blogcms/nginx/gen-cert.sh): Script tự động tạo chứng chỉ SSL/TLS chuẩn SAN bằng OpenSSL.

### 3. File Bằng chứng Tương ứng
- `evidence/buoc3-nginx.txt`: Kết quả kiểm tra cú pháp Nginx, mã chuyển hướng 301, danh sách Security Headers qua `curl -kI`, và thông tin SAN của chứng chỉ.

### 4. Danh sách Ảnh cần Chụp & Lệnh Thực thi
- **Ảnh 3.1**: Cảnh báo chứng chỉ tự ký trên trình duyệt và thông tin chi tiết chứng chỉ SAN.
  - *Thao tác*: Bấm vào biểu tượng ổ khóa cạnh URL trên Chrome/Edge -> Certificate Viewer.
- **Ảnh 3.2**: Toàn bộ Security Headers trả về qua HTTPS.
  - *Lệnh*: `curl -skI https://localhost`
- **Ảnh 3.3**: Giao diện đăng nhập pgAdmin qua subpath `/pgadmin/`.
  - *Mở trình duyệt*: `https://localhost/pgadmin/`

---

## CHƯƠNG 4: HỆ THỐNG GIÁM SÁT HIỆU NĂNG VỚI PROMETHEUS VÀ GRAFANA

### 1. Mô tả Thực tế
Hệ thống giám sát toàn diện hoạt động 24/7 không mở cổng trực tiếp ra Internet mà định tuyến an toàn qua Nginx:
- **Prometheus 2.52.0**: Thu thập chỉ số (metrics) chu kỳ 15 giây/lần từ 4 mục tiêu (targets): cAdvisor (tài nguyên container), Nginx Exporter, Postgres Exporter và bản thân Prometheus. Dữ liệu được lưu trữ TSDB với chính sách retention 7 ngày.
- **Grafana 11.0.0**: Cấu hình tự động nạp nguồn dữ liệu (Datasources Provisioning) và 4 Dashboards chuyên biệt trong thư mục `BlogCMS Monitoring`:
  1. *BlogCMS - Containers*: Biểu đồ tải CPU, mức chiếm dụng RAM, Network I/O từng container.
  2. *BlogCMS - Nginx*: Tần suất yêu cầu (Requests/sec), trạng thái kết nối active, phân bố mã phản hồi 2xx/3xx/4xx/5xx.
  3. *BlogCMS - PostgreSQL*: Số lượng kết nối backend, tần suất Commit/Rollback, dung lượng CSDL.
  4. *BlogCMS - Logs*: Trực quan hóa log tập trung và biểu đồ sự kiện an ninh.

### 2. Đường dẫn File Cấu hình Trọng tâm
- [`prometheus/prometheus.yml`](file:///home/trung/blogcms/prometheus/prometheus.yml): Cấu hình scrape configs, scrape_interval 15s cho 4 jobs.
- [`grafana/provisioning/datasources/datasources.yml`](file:///home/trung/blogcms/grafana/provisioning/datasources/datasources.yml): Provisioning tự động nguồn dữ liệu Prometheus và Loki.
- [`grafana/provisioning/dashboards/dashboards.yml`](file:///home/trung/blogcms/grafana/provisioning/dashboards/dashboards.yml): Provisioning tự động các tệp JSON dashboard vào Grafana.
- [`grafana/dashboards/containers.json`](file:///home/trung/blogcms/grafana/dashboards/containers.json): Định nghĩa Dashboard cAdvisor.
- [`grafana/dashboards/nginx.json`](file:///home/trung/blogcms/grafana/dashboards/nginx.json): Định nghĩa Dashboard Nginx.
- [`grafana/dashboards/postgres.json`](file:///home/trung/blogcms/grafana/dashboards/postgres.json): Định nghĩa Dashboard PostgreSQL.

### 3. File Bằng chứng Tương ứng
- `evidence/buoc4-giamsat.txt`: Ghi nhận sinh tải 200 requests, kết quả kiểm tra API targets (4/4 UP), dữ liệu truy vấn PromQL thực tế và Grafana Provisioning API.

### 4. Danh sách Ảnh cần Chụp & Lệnh Thực thi
- **Ảnh 4.1**: Trang Prometheus Targets hiển thị 4/4 Targets UP.
  - *Lệnh mở cổng tạm*:
    ```bash
    echo -e "services:\n  prometheus:\n    ports:\n      - '127.0.0.1:9090:9090'" > docker-compose.override.yml
    docker compose up -d prometheus
    ```
    *Mở trình duyệt*: `http://localhost:9090/targets` chụp ảnh -> sau đó chạy `rm -f docker-compose.override.yml && docker compose up -d prometheus`.
- **Ảnh 4.2**: Bảng điều khiển Grafana - Dashboard Containers (`/grafana/d/blogcms-containers`).
  - *Mở trình duyệt*: `https://localhost/grafana/` (user `admin`) -> Dashboards -> BlogCMS - Containers.
- **Ảnh 4.3**: Bảng điều khiển Grafana - Dashboard Nginx (`/grafana/d/blogcms-nginx`).
- **Ảnh 4.4**: Bảng điều khiển Grafana - Dashboard PostgreSQL (`/grafana/d/blogcms-postgres`).

---

## CHƯƠNG 5: QUẢN LÝ NHẬT KÝ TẬP TRUNG (LOKI + PROMTAIL) VÀ XỬ LÝ SỰ CỐ AN NINH

### 1. Mô tả Thực tế
Hệ thống giải quyết bài toán phân tích điều tra số (Digital Forensics) và phản ứng sự cố:
- **Loki 3.0.0 & Promtail 3.0.0**: Promtail đọc nhật ký trực tiếp từ Docker socket (`/var/run/docker.sock`), tự động bóc tách metadata container (service name, container name, stream) và vận chuyển sang Loki với chính sách lưu trữ 7 ngày.
- **Kịch bản Mô phỏng Sự cố**: Tấn công dò quét mật khẩu có chủ đích (Brute Force) vào endpoint xác thực `/login` bằng 20 requests liên tiếp nhằm vào tài khoản `admin`.
- **Phát hiện & Cảnh báo Tự động**:
  - Luật cảnh báo Grafana Alerting: `sum(count_over_time({job="webapp"} |= "LOGIN_FAILED" [1m])) > 5`.
  - Khi số lần thất bại vượt ngưỡng, Rule kích hoạt trạng thái **FIRING**, thông qua Alertmanager gửi Webhook POST tới microservice `alert-sink` lắng nghe trên cổng 9099.
- **Truy vết Forensics bằng LogQL**:
  - Tìm lần đăng nhập sai: `{job="webapp"} |= "LOGIN_FAILED"`
  - Thống kê IP tấn công: `sum by (ip) (rate({job="webapp"} |= "LOGIN_FAILED" [1m]))`
  - Thống kê mã lỗi phản hồi: `sum by (status) (count_over_time({job="nginx"} [5m]))`
  - Giám sát luồng kiểm duyệt bài viết: `{job="webapp"} |= "POST_STATUS"`

### 2. Đường dẫn File Cấu hình Trọng tâm
- [`loki/loki-config.yaml`](file:///home/trung/blogcms/loki/loki-config.yaml): Cấu hình lưu trữ filesystem, retention 7d.
- [`promtail/promtail-config.yaml`](file:///home/trung/blogcms/promtail/promtail-config.yaml): Cấu hình Docker Service Discovery và pipeline bóc tách log nhãn.
- [`grafana/provisioning/alerting/alert-rules.yaml`](file:///home/trung/blogcms/grafana/provisioning/alerting/alert-rules.yaml): Cấu hình quy tắc cảnh báo Brute Force qua LogQL.
- [`grafana/provisioning/alerting/contact-points.yaml`](file:///home/trung/blogcms/grafana/provisioning/alerting/contact-points.yaml): Cấu hình Webhook gửi sang `alert-sink:9099`.
- [`alert-sink/server.py`](file:///home/trung/blogcms/alert-sink/server.py): Microservice Python tiếp nhận và ghi nhận cảnh báo an ninh.
- [`scripts/simulate_bruteforce.sh`](file:///home/trung/blogcms/scripts/simulate_bruteforce.sh): Script mô phỏng tấn công dò quét mật khẩu.
- [`docs/su-co-bruteforce.md`](file:///home/trung/blogcms/docs/su-co-bruteforce.md): Báo cáo điều tra sự cố an toàn thông tin chuyên sâu.

### 3. File Bằng chứng Tương ứng
- `evidence/buoc5-logql.txt`: Kết quả chi tiết thực thi 5 câu truy vấn LogQL trích xuất từ API của Loki.
- `evidence/buoc5-sucodo.txt`: Hồ sơ sự cố an ninh, số liệu chặn Rate Limit và log ghi nhận Webhook FIRING tại alert-sink.

### 4. Danh sách Ảnh cần Chụp & Lệnh Thực thi
- **Ảnh 5.1**: Giao diện Grafana Explore truy vấn LogQL `{job="webapp"} |= "LOGIN_FAILED"`.
  - *Mở trình duyệt*: `https://localhost/grafana/explore` -> chọn Datasource Loki -> dán LogQL query -> Run query.
- **Ảnh 5.2**: Quy tắc cảnh báo Alert Rule chuyển trạng thái Firing (Màu đỏ).
  - *Mở trình duyệt*: `https://localhost/grafana/alerting/list` -> xem rule `BlogCMS - Brute force login`.
- **Ảnh 5.3**: Terminal ghi nhận dòng log Webhook FIRING nhận được tại container `alert-sink`.
  - *Lệnh*: `docker compose logs alert-sink | tail -n 15`

---

## CHƯƠNG 6: GIA CỐ AN TOÀN HỆ THỐNG (HARDENING) VÀ QUÉT LỖ HỔNG BẢO MẬT TRIVY

### 1. Mô tả Thực tế
Hệ thống được gia cố toàn diện theo các khuyến nghị bảo mật khắt khe của chuẩn CIS Docker Benchmark:
1. **Non-Root Containers**: 100% dịch vụ ứng dụng chạy người dùng không đặc quyền (`web` dùng `node:1000`, `nginx` dùng `nginx:101`, `prometheus`/`exporters` dùng `nobody:65534`, `grafana` dùng `grafana:472`, `loki` và `alert-sink` dùng `10001:10001`).
2. **Read-Only Root Filesystem**: Khóa hệ thống tệp gốc chế độ chỉ đọc (`read_only: true`). Các thư mục cần ghi bộ đệm tạm được ánh xạ bằng `tmpfs` đi kèm các cờ vô hiệu hóa thực thi `rw,noexec,nosuid`.
3. **Thu hồi Quyền Hạt nhân & Chống Nâng quyền**: Áp dụng `cap_drop: [ALL]` trên tất cả container và kích hoạt `security_opt: ["no-new-privileges:true"]`.
4. **Giới hạn Tài nguyên (Resource Constraints)**: Thiết lập trần tài nguyên nghiêm ngặt (CPU và Memory limits) trên mọi dịch vụ.
5. **Nginx Rate Limiting**: Chống brute force trên `/login` (5 yêu cầu/phút), chống spam bình luận (10 yêu cầu/phút), trả về mã `429 Too Many Requests`.
6. **Loại bỏ Lỗ hổng Image với Trivy 0.50.2**:
   - Thay thế thư viện gốc `bcrypt` (C++ native có lỗ hổng trong `node-tar`) bằng `bcryptjs` (thuần JavaScript).
   - Nâng cấp các gói hệ điều hành Alpine cơ sở qua `apk upgrade --no-cache`.
   - Loại bỏ hoàn toàn các trình quản lý gói (`npm`, `yarn`, `pip`, `make`, `g++`) khỏi image sản phẩm cuối.
   - **Kết quả quét**: Đạt **0 lỗ hổng CRITICAL** và **0 lỗ hổng HIGH** trên các image tự build (`blogcms-web` và `blogcms-alert-sink`).

### 2. Đường dẫn File Cấu hình Trọng tâm
- [`web/Dockerfile`](file:///home/trung/blogcms/web/Dockerfile): Dockerfile tối ưu đa tầng, non-root `USER node`, loại bỏ dev packages.
- [`alert-sink/Dockerfile`](file:///home/trung/blogcms/alert-sink/Dockerfile): Dockerfile Python non-root `USER appuser`, loại bỏ pip/wheel.
- [`scripts/run_trivy_scan.sh`](file:///home/trung/blogcms/scripts/run_trivy_scan.sh): Kịch bản quét lỗ hổng tự động với công cụ `aquasec/trivy:0.50.2`.

### 3. File Bằng chứng Tương ứng
- `evidence/buoc6-trivy.txt`: Báo cáo quét lỗ hổng chi tiết trên toàn bộ 6 hình ảnh container cốt lõi.
- `evidence/final-smoke-test.txt`: Bằng chứng kiểm thử tự động toàn diện từ trạng thái sạch đạt 100%.

### 4. Danh sách Ảnh cần Chụp & Lệnh Thực thi
- **Ảnh 6.1**: Báo cáo quét Trivy cho thấy `blogcms-web: Total 0 (HIGH: 0, CRITICAL: 0)`.
  - *Lệnh*: `docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.50.2 image --severity HIGH,CRITICAL blogcms-web`
- **Ảnh 6.2**: Báo cáo quét Trivy cho thấy `blogcms-alert-sink: Total 0 (HIGH: 0, CRITICAL: 0)`.
  - *Lệnh*: `docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.50.2 image --severity HIGH,CRITICAL blogcms-alert-sink`
- **Ảnh 6.3**: Kiểm tra quyền non-root thực tế bên trong container web.
  - *Lệnh*: `docker compose exec -T web id` (Kết quả: `uid=1000(node) gid=1000(node)`)
- **Ảnh 6.4**: Kiểm tra hệ thống tệp chỉ đọc (Read-only filesystem) ngăn chặn ghi tệp độc hại.
  - *Lệnh*: `docker compose exec -T web touch /app/hacked.txt` (Kết quả: `touch: /app/hacked.txt: Read-only file system`)

---

## KẾT LUẬN VÀ ĐÁNH GIÁ CHUNG

1. **Kết quả đạt được**:
   - Triển khai hoàn chỉnh, tự động hóa 100% stack Blog/CMS gồm 12 microservices hoạt động ổn định trên Docker Desktop/WSL2.
   - Đáp ứng trọn vẹn toàn bộ các tiêu chí từ Nghiệp vụ (RBAC, CRUD, Magic Bytes, RSS), Mạng & SSL (HTTPS, HTTP/2, Ciphers, Security Headers), Giám sát (Prometheus, 4 Dashboards Grafana), Ghi log (Loki, Promtail, Alerting Webhook), đến Gia cố An ninh (Non-root, Read-only FS, Trivy 0 CVE).
   - Kiểm chứng thành công khả năng tự động khởi tạo từ trạng thái sạch bằng 1 lệnh duy nhất.
2. **Hạn chế & Hướng phát triển**:
   - Hiện tại chứng chỉ HTTPS là chứng chỉ tự ký (Self-signed) phù hợp môi trường nội bộ/lab; khi triển khai Internet công cộng cần tích hợp Certbot / Let's Encrypt với giao thức ACME tự động gia hạn.
   - Phiên làm việc (Session) của webapp hiện lưu trên MemoryStore phục vụ đơn phiên bản; có thể nâng cấp sử dụng Redis Cluster khi cần mở rộng quy mô đa instance (Horizontal Pod Autoscaling).
