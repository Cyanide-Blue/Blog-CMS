-- =============================================================================
-- DTC245180035 - Blog/CMS PostgreSQL Database Initialization
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    bio TEXT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('member', 'author', 'admin')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    author_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    excerpt TEXT NOT NULL,
    content TEXT NOT NULL,
    cover_image_path VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'published', 'rejected', 'archived')),
    review_note TEXT NULL,
    view_count INT NOT NULL DEFAULT 0 CHECK (view_count >= 0),
    published_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_tags (
    post_id INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    tag_id INT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    post_id INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id INT NULL REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 1000),
    status VARCHAR(20) NOT NULL DEFAULT 'approved' CHECK (status IN ('approved', 'hidden')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS media (
    id SERIAL PRIMARY KEY,
    uploaded_by INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_path VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes INT NOT NULL CHECK (size_bytes > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_status_published_at ON posts (status, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_category_id ON posts (category_id);
CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts (author_id);
CREATE INDEX IF NOT EXISTS idx_comments_post_created ON comments (post_id, created_at);
CREATE INDEX IF NOT EXISTS idx_post_tags_tag_id ON post_tags (tag_id);

-- SEED USERS
INSERT INTO users (id, username, email, password_hash, full_name, bio, role, is_active, created_at) VALUES
(1, 'admin', 'admin@blogcms.local', '$2a$10$po3LAATFnU2vHTOElL42HelP1FTYwJog0quJV.pinVlrzhXy1/yFO', 'Quản Trị Viên', 'Quản trị viên toàn quyền hệ thống Blog/CMS DTC245180035.', 'admin', true, NOW() - INTERVAL '90 days'),
(2, 'tacgia01', 'tacgia01@blogcms.local', '$2a$10$po3LAATFnU2vHTOElL42HelP1FTYwJog0quJV.pinVlrzhXy1/yFO', 'Nguyễn Văn Tác', 'Kỹ sư phần mềm đam mê kiến trúc Microservices và phân tán.', 'author', true, NOW() - INTERVAL '80 days'),
(3, 'tacgia02', 'tacgia02@blogcms.local', '$2a$10$po3LAATFnU2vHTOElL42HelP1FTYwJog0quJV.pinVlrzhXy1/yFO', 'Trần Thị Bút', 'DevOps Engineer yêu thích tự động hóa, CI/CD và observability.', 'author', true, NOW() - INTERVAL '75 days'),
(4, 'docgia01', 'docgia01@blogcms.local', '$2a$10$po3LAATFnU2vHTOElL42HelP1FTYwJog0quJV.pinVlrzhXy1/yFO', 'Lê Độc Giả', 'Sinh viên năm cuối ngành Kỹ thuật Phần mềm.', 'member', true, NOW() - INTERVAL '60 days'),
(5, 'docgia02', 'docgia02@blogcms.local', '$2a$10$po3LAATFnU2vHTOElL42HelP1FTYwJog0quJV.pinVlrzhXy1/yFO', 'Phạm Đọc Sách', 'Độc giả yêu công nghệ và thích tìm hiểu các thủ thuật mới.', 'member', true, NOW() - INTERVAL '50 days')
ON CONFLICT (id) DO NOTHING;

SELECT setval('users_id_seq', 5);

-- SEED CATEGORIES
INSERT INTO categories (id, name, slug, description, sort_order) VALUES
(1, 'Công nghệ', 'cong-nghe', 'Tin tức, xu hướng và giải pháp công nghệ hiện đại.', 1),
(2, 'Lập trình', 'lap-trinh', 'Kỹ thuật viết mã sạch, giải thuật và phát triển phần mềm.', 2),
(3, 'DevOps & Hạ tầng', 'devops-ha-tang', 'Triển khai, tự động hóa, container và quản trị hạ tầng.', 3),
(4, 'Đời sống sinh viên', 'doi-song-sinh-vien', 'Kinh nghiệm học tập, thực tập và kỹ năng mềm sinh viên IT.', 4),
(5, 'Thủ thuật', 'thu-thuat', 'Mẹo tối ưu hiệu suất, cấu hình công cụ và giải quyết sự cố.', 5)
ON CONFLICT (id) DO NOTHING;

SELECT setval('categories_id_seq', 5);

-- SEED TAGS
INSERT INTO tags (id, name, slug) VALUES
(1, 'Docker', 'docker'),
(2, 'Node.js', 'nodejs'),
(3, 'PostgreSQL', 'postgresql'),
(4, 'DevOps', 'devops'),
(5, 'Bảo mật', 'bao-mat'),
(6, 'Microservices', 'microservices'),
(7, 'Sinh viên', 'sinh-vien'),
(8, 'Clean Code', 'clean-code'),
(9, 'Linux', 'linux'),
(10, 'Monitoring', 'monitoring')
ON CONFLICT (id) DO NOTHING;

SELECT setval('tags_id_seq', 10);


-- SEED POSTS

INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (1, 2, 1, 'Kiến trúc Microservices hiện đại với Docker', 'kien-truc-microservices-hien-dai-voi-docker', 'Tìm hiểu cách thiết kế và triển khai kiến trúc Microservices chuẩn sản xuất sử dụng Docker và containerization.', '# Kiến trúc Microservices hiện đại với Docker

Trong thời đại điện toán đám mây, kiến trúc Microservices đã trở thành tiêu chuẩn cho hệ thống lớn. Mỗi dịch vụ đảm nhận một nghiệp vụ cụ thể và giao tiếp qua REST/gRPC.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-1.svg', 'published', NULL, 342, NOW() - INTERVAL '70 days', NOW() - INTERVAL '75 days', NOW() - INTERVAL '75 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (2, 2, 2, 'Làm chủ Node.js và Event Loop nâng cao', 'lam-chu-nodejs-va-event-loop-nang-cao', 'Khám phá sâu cơ chế vận hành bất đồng bộ, Event Loop và cách xử lý non-blocking I/O trong Node.js.', '# Làm chủ Node.js và Event Loop nâng cao

Node.js xây dựng trên V8 Engine của Google Chrome. Điểm cốt lõi giúp xử lý hàng vạn kết nối đồng thời là mô hình non-blocking I/O điều khiển bằng sự kiện.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-2.svg', 'published', NULL, 510, NOW() - INTERVAL '65 days', NOW() - INTERVAL '68 days', NOW() - INTERVAL '68 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (3, 3, 3, 'Triển khai Docker Compose chuẩn Production', 'trien-khai-docker-compose-chuan-production', 'Hướng dẫn chi tiết cách cấu hình Docker Compose với Network Isolation, Healthcheck và bảo mật container.', '# Triển khai Docker Compose chuẩn Production

Docker Compose là công cụ tuyệt vời để định nghĩa và chạy ứng dụng đa container. Trên production, cần chú trọng phân tách mạng frontend/backend và cấu hình healthcheck.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-3.svg', 'published', NULL, 420, NOW() - INTERVAL '60 days', NOW() - INTERVAL '62 days', NOW() - INTERVAL '62 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (4, 3, 4, 'Kỹ năng quản lý thời gian cho sinh viên IT', 'ky-nang-quan-ly-thoi-gian-cho-sinh-vien-it', 'Chia sẻ phương pháp cân bằng giữa đồ án, tự học công nghệ mới và đời sống sinh viên năng động.', '# Kỹ năng quản lý thời gian cho sinh viên IT

Sinh viên IT đối mặt lượng kiến thức công nghệ khổng lồ. Ứng dụng kỹ thuật Pomodoro và nguyên lý 80/20 giúp tập trung vào các kiến thức nền tảng giá trị nhất.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-4.svg', 'published', NULL, 195, NOW() - INTERVAL '55 days', NOW() - INTERVAL '58 days', NOW() - INTERVAL '58 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (5, 2, 5, 'Tối ưu hóa truy vấn PostgreSQL thực chiến', 'toi-uu-hoa-truy-van-postgresql-thuc-chien', 'Bí quyết đánh chỉ mục (Index), đọc kế hoạch thực thi EXPLAIN ANALYZE và tối ưu hóa hiệu năng PostgreSQL.', '# Tối ưu hóa truy vấn PostgreSQL thực chiến

PostgreSQL là cơ sở dữ liệu quan hệ mạnh mẽ. Khi dữ liệu lớn, đọc EXPLAIN ANALYZE và đánh Composite Index sẽ giúp giảm thời gian truy vấn từ giây xuống mili-giây.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-5.svg', 'published', NULL, 380, NOW() - INTERVAL '50 days', NOW() - INTERVAL '52 days', NOW() - INTERVAL '52 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (6, 1, 1, 'Xu hướng AI và Machine Learning năm 2026', 'xu-huong-ai-va-machine-learning-nam-2026', 'Tổng quan về sự phát triển của các mô hình ngôn ngữ lớn, AI Agent và ứng dụng thực tiễn trong công nghiệp.', '# Xu hướng AI và Machine Learning năm 2026

AI Agentic năm 2026 có khả năng tự động phân tích yêu cầu, sử dụng công cụ CLI/API và tự sửa lỗi trong quá trình lập trình phần mềm.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-6.svg', 'published', NULL, 290, NOW() - INTERVAL '45 days', NOW() - INTERVAL '48 days', NOW() - INTERVAL '48 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (7, 2, 2, 'Clean Code và Refactoring trong JavaScript', 'clean-code-va-refactoring-trong-javascript', 'Nguyên tắc viết mã sạch, dễ bảo trì và các mẫu tái cấu trúc mã nguồn thông dụng trong JavaScript hiện đại.', '# Clean Code và Refactoring trong JavaScript

Viết mã sạch theo nguyên lý đơn nhiệm và áp dụng quy tắc Hướng đạo sinh giúp mã nguồn dự án luôn dễ đọc, dễ bảo trì và giảm thiểu lỗi.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-7.svg', 'published', NULL, 230, NOW() - INTERVAL '40 days', NOW() - INTERVAL '42 days', NOW() - INTERVAL '42 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (8, 3, 3, 'Giám sát hệ thống với Prometheus và Grafana', 'giam-sat-he-thong-voi-prometheus-va-grafana', 'Dựng hệ thống giám sát toàn diện cho ứng dụng Web, Database và Container với bộ đôi công cụ mã nguồn mở.', '# Giám sát hệ thống với Prometheus và Grafana

Prometheus hoạt động theo cơ chế pull metrics từ cAdvisor, Nginx Exporter, Postgres Exporter và hiển thị trực quan trên Grafana.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-8.svg', 'published', NULL, 310, NOW() - INTERVAL '35 days', NOW() - INTERVAL '38 days', NOW() - INTERVAL '38 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (9, 3, 4, 'Hành trang phỏng vấn thực tập sinh DevOps', 'hanh-trang-phong-van-thuc-tap-sinh-devops', 'Kinh nghiệm chuẩn bị CV, ôn tập kiến thức cốt lõi và trả lời câu hỏi phỏng vấn vị trí Thực tập sinh DevOps.', '# Hành trang phỏng vấn thực tập sinh DevOps

Chuẩn bị vững chắc kiến thức Linux, Docker, Git và CI/CD giúp sinh viên tự tin ghi điểm trước nhà tuyển dụng trong các vòng phỏng vấn kỹ thuật.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-9.svg', 'published', NULL, 275, NOW() - INTERVAL '30 days', NOW() - INTERVAL '32 days', NOW() - INTERVAL '32 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (10, 1, 5, 'Bảo mật Web với HTTPS và Security Headers', 'bao-mat-web-voi-https-va-security-headers', 'Cấu hình Nginx với SSL/TLS mạnh mẽ, HSTS, Content Security Policy và các tiêu chuẩn bảo mật OWASP.', '# Bảo mật Web với HTTPS và Security Headers

Bảo vệ ứng dụng web qua Nginx reverse proxy với SSL/TLS tự ký, các tiêu đề OWASP như CSP, X-Frame-Options và cookie SameSite Strict.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-10.svg', 'published', NULL, 350, NOW() - INTERVAL '25 days', NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (11, 2, 1, 'Kiến trúc Event-Driven với Message Queue', 'kien-truc-event-driven-voi-message-queue', 'Giải pháp giải phóng nghẽn cổ chai và tách rời các thành phần hệ thống bằng hàng đợi thông điệp.', '# Kiến trúc Event-Driven với Message Queue

Hàng đợi sự kiện giúp phân tách nhà sản xuất và người tiêu thụ thông điệp, đệm tải và xử lý bất đồng bộ mượt mà trong các giờ cao điểm.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-11.svg', 'published', NULL, 180, NOW() - INTERVAL '20 days', NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (12, 2, 2, 'Xây dựng RESTful API chuẩn OpenAPI', 'xay-dung-restful-api-chuan-openapi', 'Phương pháp thiết kế API rõ ràng, phiên bản hóa và tự động sinh tài liệu Swagger/OpenAPI tương tác.', '# Xây dựng RESTful API chuẩn OpenAPI

Thiết kế tài nguyên danh từ số nhiều, sử dụng đúng HTTP verbs và mã phản hồi chuẩn giúp API dễ tích hợp và tự động hóa tài liệu.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-12.svg', 'published', NULL, 215, NOW() - INTERVAL '15 days', NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (13, 2, 5, 'Kỹ thuật tối ưu hóa bộ nhớ đệm với Redis', 'ky-thuat-toi-uu-hoa-bo-nho-dem-voi-redis', 'Hướng dẫn ứng dụng Redis Caching để tăng tốc độ phản hồi trang web và giảm tải cho PostgreSQL.', '# Kỹ thuật tối ưu hóa bộ nhớ đệm với Redis

Mô hình Cache-Aside giúp giảm tải cho cơ sở dữ liệu và tăng tốc độ đọc dữ liệu trang chủ xuống dưới 2ms.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-13.svg', 'draft', NULL, 0, NULL, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (14, 3, 3, 'Xây dựng pipeline CI/CD với GitHub Actions', 'xay-dung-pipeline-ci-cd-voi-github-actions', 'Tự động hóa kiểm thử mã nguồn, build Docker image và quét lỗ hổng bảo mật với GitHub Actions.', '# Xây dựng pipeline CI/CD với GitHub Actions

Tự động hóa toàn bộ vòng đời kiểm thử, quét lỗ hổng bảo mật container và triển khai liên tục vào môi trường thử nghiệm.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-14.svg', 'pending', NULL, 0, NULL, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO posts (id, author_id, category_id, title, slug, excerpt, content, cover_image_path, status, review_note, view_count, published_at, created_at, updated_at)
VALUES (15, 2, 5, 'Bảo mật API với JSON Web Token', 'bao-mat-api-voi-json-web-token', 'Phân tích cơ chế hoạt động của JWT, các lỗ hổng thường gặp và cách triển khai Access/Refresh Token an toàn.', '# Bảo mật API với JSON Web Token

Phân tích cấu trúc Header, Payload, Signature của JWT và phương thức bảo vệ token trước nguy cơ tấn công XSS.

## 1. Tổng quan vấn đề và bối cảnh áp dụng
Trong quá trình phát triển và vận hành hệ thống phần mềm thực tế, việc nắm vững các nguyên lý kiến trúc cốt lõi là chìa khóa để xây dựng các giải pháp ổn định, bảo mật và có khả năng mở rộng cao. Khi lưu lượng truy cập gia tăng nhanh chóng, các điểm nghẽn về hạ tầng, cơ sở dữ liệu hay mô hình lập trình sẽ bộc lộ rõ rệt.

- **Hiệu năng và tính sẵn sàng**: Cần phải tối ưu hóa đồng bộ từ tầng mã nguồn backend, cấu hình web server cho tới thiết kế cơ sở dữ liệu.
- **Tính tự động hóa và chuẩn hóa**: Hạn chế tối đa sự can thiệp thủ công bằng các công cụ Docker Compose, tự động hóa CI/CD và quy chuẩn mã nguồn nghiêm ngặt.
- **Khả năng quan sát (Observability)**: Mọi sự cố cần phải được phát hiện sớm thông qua hệ thống đo lường metrics và ghi log tập trung.

## 2. Các bước triển khai kỹ thuật chi tiết
Dưới đây là đoạn mã nguồn mẫu minh họa cách tiếp cận và giải quyết bài toán:

```javascript
// Minh họa cấu hình xử lý bất đồng bộ chuẩn mực
const express = require(''express'');
const app = express();

app.get(''/api/resource'', async (req, res) => {
    try {
        const result = await processTaskAsync(req.query);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error(''Lỗi thực thi:'', error.message);
        res.status(500).json({ error: ''Lỗi máy chủ nội bộ'' });
    }
});
```

## 3. Đánh giá và kết luận
Áp dụng đúng chuẩn kỹ thuật không chỉ giúp hệ thống chạy ổn định mà còn tiết kiệm tài nguyên phần cứng đáng kể. Hãy luôn kiểm tra tính toàn vẹn của dữ liệu và ghi nhận log kiểm toán đầy đủ.', '/images/covers/cover-15.svg', 'rejected', 'Bài viết cần bổ sung thêm ví dụ thực tế về middleware xác thực trong Express và giải thích chi tiết hơn về cơ chế Refresh Token trước khi xuất bản.', 0, NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

SELECT setval('posts_id_seq', 15);


-- SEED POST TAGS

INSERT INTO post_tags (post_id, tag_id) VALUES (1, 1) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (1, 4) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (1, 6) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (2, 2) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (2, 8) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (3, 1) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (3, 4) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (3, 5) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (4, 7) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (4, 8) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (5, 3) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (5, 5) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (5, 8) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (6, 6) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (6, 5) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (7, 2) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (7, 8) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (8, 4) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (8, 10) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (8, 1) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (9, 7) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (9, 4) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (9, 9) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (10, 5) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (10, 4) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (11, 6) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (11, 2) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (12, 2) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (12, 8) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (13, 3) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (13, 8) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (14, 4) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (14, 1) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (15, 5) ON CONFLICT DO NOTHING;
INSERT INTO post_tags (post_id, tag_id) VALUES (15, 2) ON CONFLICT DO NOTHING;

-- SEED COMMENTS

INSERT INTO comments (id, post_id, user_id, parent_id, content, status, created_at) VALUES (1, 1, 4, NULL, 'Bài viết về Microservices rất chi tiết và dễ hiểu! Cảm ơn tác giả nhiều.', 'approved', NOW() - INTERVAL '69 days') ON CONFLICT (id) DO NOTHING;
INSERT INTO comments (id, post_id, user_id, parent_id, content, status, created_at) VALUES (2, 1, 2, 1, 'Cảm ơn bạn đã đọc bài! Nếu có thắc mắc về phân vùng network hãy để lại câu hỏi nhé.', 'approved', NOW() - INTERVAL '68 days') ON CONFLICT (id) DO NOTHING;
INSERT INTO comments (id, post_id, user_id, parent_id, content, status, created_at) VALUES (3, 2, 5, NULL, 'Event Loop trong Node.js trước giờ mình vẫn hay mơ hồ, đọc xong bài này sáng tỏ hẳn ra.', 'approved', NOW() - INTERVAL '64 days') ON CONFLICT (id) DO NOTHING;
INSERT INTO comments (id, post_id, user_id, parent_id, content, status, created_at) VALUES (4, 3, 4, NULL, 'Các nguyên tắc phân tách mạng trong Docker Compose quá chuẩn. Mình đã áp dụng ngay vào đồ án.', 'approved', NOW() - INTERVAL '59 days') ON CONFLICT (id) DO NOTHING;
INSERT INTO comments (id, post_id, user_id, parent_id, content, status, created_at) VALUES (5, 5, 5, NULL, 'Rất đồng ý với việc dùng tham số hóa trong SQL để chống SQL Injection.', 'approved', NOW() - INTERVAL '49 days') ON CONFLICT (id) DO NOTHING;
INSERT INTO comments (id, post_id, user_id, parent_id, content, status, created_at) VALUES (6, 5, 2, 5, 'Đúng vậy bạn, tham số hóa truy vấn là tiêu chuẩn bắt buộc cho mọi ứng dụng web an toàn.', 'approved', NOW() - INTERVAL '48 days') ON CONFLICT (id) DO NOTHING;
INSERT INTO comments (id, post_id, user_id, parent_id, content, status, created_at) VALUES (7, 10, 4, NULL, 'Cấu hình Nginx Security Headers rất hữu ích, mong có thêm bài về Rate Limiting nữa ạ.', 'approved', NOW() - INTERVAL '24 days') ON CONFLICT (id) DO NOTHING;

SELECT setval('comments_id_seq', 7);
