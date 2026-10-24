# Danh sách phiên bản hình ảnh Docker (Cố định Tag)

| Thành phần | Image | Tag cố định | Mục đích |
|---|---|---|---|
| Web Blog/CMS | node | 20.14.0-alpine3.20 | Ứng dụng web chính (chạy non-root node:node, read-only FS) |
| CSDL | postgres | 16.3-alpine3.20 | Cơ sở dữ liệu quan hệ (non-root postgres) |
| Quản lý DB | dpage/pgadmin4 | 8.8 | Giao diện web quản trị DB |
| Reverse Proxy | nginxinc/nginx-unprivileged | 1.27-alpine | Proxy không đặc quyền (uid 101), SSL/TLS, Security Headers |
| Giám sát | prom/prometheus | v2.52.0 | Thu thập metrics (non-root nobody:65534) |
| Trực quan hóa | grafana/grafana | 11.0.0 | Dashboard hiển thị metrics (non-root 472:472) |
| Metrics Container | gcr.io/cadvisor/cadvisor | v0.49.1 | Giám sát tài nguyên phần cứng/container |
| Nginx Exporter | nginx/nginx-prometheus-exporter | 1.2.0 | Xuất metrics Nginx (non-root 65534:65534) |
| Postgres Exporter | prometheuscommunity/postgres-exporter | v0.15.0 | Xuất metrics PostgreSQL (non-root 65534:65534) |
| Log Engine | grafana/loki | 3.0.0 | Lưu trữ log tập trung (non-root 10001:10001) |
| Log Shipper | grafana/promtail | 3.0.0 | Đẩy log về Loki (truy cập docker socket) |
| Alert Receiver | python | 3.11-alpine | Tiếp nhận cảnh báo Webhook (non-root 10001:10001) |
