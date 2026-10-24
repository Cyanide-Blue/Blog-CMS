# BÁO CÁO ĐIỀU TRA SỰ CỐ AN TOÀN THÔNG TIN: TẤN CÔNG DÒ MẬT KHẨU (BRUTE FORCE)

- **Hệ thống**: Blog/CMS Nền tảng Đa tác giả (Dockerized Microservices)
- **Học viên thực hiện**: Hà Đức Trung
- **Mã số sinh viên**: DTC245180035
- **Mã sự cố**: `INC-20261023-BRUTEFORCE-01`
- **Mức độ nghiêm trọng**: **CRITICAL** (Nghiêm trọng)
- **Thời gian xảy ra**: 2026-10-23 17:01:14 UTC – 17:01:26 UTC

---

## 1. Mô tả Sự cố (Incident Description)

Vào lúc 17:01:14 UTC ngày 23/10/2026, hệ thống giám sát an ninh ghi nhận một đợt tấn công từ chối dịch vụ tầng ứng dụng và dò quét mật khẩu có chủ đích nhằm vào endpoint xác thực người dùng `https://localhost/login`.

Kẻ tấn công sử dụng công cụ tự động hóa gửi liên tiếp **20 yêu cầu đăng nhập sai** với tên tài khoản nhắm tới là **`admin`** cùng từ điển các mật khẩu thông dụng (`admin123`, `password`, `12345678`, `qwerty123`...) với tần suất cao (~0.5 giây / yêu cầu). Kẻ tấn công đã mô phỏng phiên làm việc hợp lệ, tự động trích xuất mã CSRF token và đính kèm cookie phiên nhằm vượt qua lớp phòng thủ chống tấn công CSRF.

---

## 2. Cơ chế Phát hiện & Kích hoạt Cảnh báo (Detection & Alerting)

### 2.1. Cấu hình Luật Cảnh báo (Alert Rule)
Hệ thống sử dụng **Grafana Alerting** kết nối trực tiếp với nguồn dữ liệu log tập trung **Loki**:
- **Tên Rule**: `BlogCMS - Brute force login`
- **Thư mục giám sát**: `BlogCMS Security`
- **Biểu thức truy vấn LogQL**:
  ```logql
  sum(count_over_time({job="webapp"} |= "LOGIN_FAILED" [1m]))
  ```
- **Điều kiện kích hoạt**: Giá trị đếm số sự kiện `LOGIN_FAILED` trong cửa sổ trượt 1 phút vượt ngưỡng **> 5 lần**.
- **Chu kỳ kiểm tra**: 10 giây / lần; thời gian trễ chờ kích hoạt: `0s`.

### 2.2. Tiến trình Kích hoạt Cảnh báo Thực tế
1. **Trước cuộc tấn công**:
   - Trạng thái Rule trên Grafana API: `Normal (NoData)` do không có bất kỳ hành vi đăng nhập sai nào.
2. **Trong cuộc tấn công**:
   - Các dòng log xác thực thất bại được webapp ghi nhận vào stdout và Promtail đẩy tức thời sang Loki.
   - Khi số lần sai vượt quá 5 lần, biểu thức điều kiện chuyển thành True (`value = 20`).
3. **Kích hoạt Firing & Gửi Webhook**:
   - Alert Rule chuyển trạng thái sang **`Alerting (Firing)`**.
   - Alertmanager tự động kích hoạt Contact Point `alert-sink-webhook` gửi POST request tới container `alert-sink` trên cổng nội bộ `9099`.
   - **Trích xuất log thực tế từ container `alert-sink`**:
     ```text
     [ALERT-SINK] timestamp=2026-10-23T17:01:25.022989+00:00 status=FIRING title='[FIRING:1] BlogCMS - Brute force login (security BlogCMS Security critical)' count=1
       -> [1] BlogCMS - Brute force login (CRITICAL): Phát hiện hơn 5 lần đăng nhập thất bại (LOGIN_FAILED) trong vòng 1 phút. Dùng LogQL: {job="webapp"} |= "LOGIN_FAILED" để truy vết IP nguồn và tài khoản bị nhắm tới.
     ```

---

## 3. Điều tra & Truy vết Nhật ký qua LogQL (Forensics)

Kỹ sư DevOps sử dụng nguồn dữ liệu Loki trên giao diện Grafana Explore để tiến hành điều tra truy vết:

### 3.1. Truy vấn Xác định Hành vi Đăng nhập Thất bại
- **Câu lệnh LogQL**:
  ```logql
  {job="webapp"} |= "LOGIN_FAILED"
  ```
- **Kết quả điều tra thực tế**:
  ```text
  [AUTH_FAIL] timestamp=2026-10-23T17:01:14.642Z ip=172.18.0.1 user=admin reason=wrong_password LOGIN_FAILED
  [AUTH_FAIL] timestamp=2026-10-23T17:01:15.241Z ip=172.18.0.1 user=admin reason=wrong_password LOGIN_FAILED
  ...
  [AUTH_FAIL] timestamp=2026-10-23T17:01:25.835Z ip=172.18.0.1 user=admin reason=wrong_password LOGIN_FAILED
  ```
- **Thông tin bóc tách**:
  - **Địa chỉ IP nguồn**: `172.18.0.1` (Địa chỉ Gateway mạng bridge Docker Desktop chuyển tiếp từ máy trạm).
  - **Tài khoản đích**: `admin`.
  - **Nguyên nhân**: `wrong_password` (Mật khẩu sai).
  - **Số lượng lần thử**: 20 lần.
  - **Khoảng thời gian**: Từ `17:01:14 UTC` đến `17:01:26 UTC` (Thời lượng tấn công 12 giây).

### 3.2. Đối chiếu Chéo với Nhật ký Máy chủ Web Nginx
- **Câu lệnh LogQL**:
  ```logql
  {job="nginx"} status="401"
  ```
- **Kết quả đối chiếu**:
  ```text
  172.18.0.1 - - [23/Oct/2026:17:01:20 +0000] "POST /login HTTP/2.0" 401 3038 "-" "curl/7.81.0" "-" rt=0.055
  172.18.0.1 - - [23/Oct/2026:17:01:21 +0000] "POST /login HTTP/2.0" 401 3038 "-" "curl/7.81.0" "-" rt=0.066
  172.18.0.1 - - [23/Oct/2026:17:01:22 +0000] "POST /login HTTP/2.0" 401 3038 "-" "curl/7.81.0" "-" rt=0.058
  ```
- **Nhận định**: Cả 20 yêu cầu đều đến từ cùng User-Agent `curl/7.81.0`, gửi bằng giao thức `HTTP/2.0` qua cổng bảo mật HTTPS (443), thời gian xử lý trung bình `0.055s`.

---

## 4. Biện pháp Xử lý & Khắc phục Đề xuất (Mitigation)

### 4.1. Gia cố Tức thời ở Tầng Nginx Reverse Proxy (Đã áp dụng)
Thiết lập cơ chế Rate Limiting tại tầng Nginx để ngăn chặn các yêu cầu vượt ngưỡng trước khi chạm tới ứng dụng Node.js:
1. Định nghĩa bộ nhớ chia sẻ theo dõi IP trong khối `http`:
   ```nginx
   limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;
   limit_req_status 429;
   ```
2. Áp dụng giới hạn riêng cho endpoint đăng nhập:
   ```nginx
   location = /login {
       limit_req zone=login_limit burst=3 nodelay;
       proxy_pass http://web_backend;
       ...
   }
   ```
*Kết quả sau gia cố*: Khi kẻ tấn công gửi liên tiếp 20 request, 3 request đầu tiên được xử lý (burst), từ request thứ 4 trở đi Nginx phản hồi ngay lập tức mã trạng thái **`HTTP 429 Too Many Requests`** mà không tiêu tốn tài nguyên của ứng dụng web hay database.

### 4.2. Giải pháp Kiến trúc Lâu dài
1. **Khóa tài khoản tạm thời (Account Lockout)**: Khóa tài khoản 15 phút nếu nhập sai quá 5 lần liên tiếp.
2. **Cơ chế CAPTCHA**: Kích hoạt reCAPTCHA / Cloudflare Turnstile sau 3 lần đăng nhập thất bại.
3. **Xác thực đa yếu tố (MFA / 2FA)**: Bắt buộc tài khoản có quyền Quản trị viên (`admin`) và Tác giả (`author`) phải sử dụng mã OTP (TOTP).

---

## 5. Bài học Kinh nghiệm (Lessons Learned)

1. **Hiệu quả của Hạ tầng Giám sát Tập trung (Loki + Promtail)**: Việc gom log thời gian thực giúp đội ngũ vận hành phát hiện và truy vết dấu hiệu tấn công chỉ trong vòng **dưới 15 giây**, thay vì phải vào từng container để đọc file log riêng lẻ.
2. **Nguyên tắc Phòng thủ theo Chiều sâu (Defense in Depth)**: Không nên để ứng dụng phụ trách toàn bộ việc ngăn chặn Brute Force. Reverse Proxy (Nginx) cần đóng vai trò là "khiên chắn" đầu tiên lọc tải độc hại.
3. **An ninh Dữ liệu Giám sát**: Không lưu trực tiếp địa chỉ IP vào Label của Loki để tránh bùng nổ cardinality, thay vào đó phân tích IP từ nội dung log stream giúp hệ thống vận hành bền bỉ và tiết kiệm RAM.
