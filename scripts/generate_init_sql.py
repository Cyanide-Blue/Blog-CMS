import bcrypt
import os

admin_hash = bcrypt.hashpw(b"123456", bcrypt.gensalt(10)).decode("utf-8")
author_hash = bcrypt.hashpw(b"123456", bcrypt.gensalt(10)).decode("utf-8")
member_hash = bcrypt.hashpw(b"123456", bcrypt.gensalt(10)).decode("utf-8")

sql = f"""-- =============================================================================
-- DTC245180035 - Blog/CMS PostgreSQL Database Initialization
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    bio TEXT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN (\x27member\x27, \x27author\x27, \x27admin\x27)),
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
    status VARCHAR(20) NOT NULL DEFAULT \x27draft\x27 CHECK (status IN (\x27draft\x27, \x27pending\x27, \x27published\x27, \x27rejected\x27, \x27archived\x27)),
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
    status VARCHAR(20) NOT NULL DEFAULT \x27approved\x27 CHECK (status IN (\x27approved\x27, \x27hidden\x27)),
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

INSERT INTO users (id, username, email, password_hash, full_name, bio, role, is_active, created_at) VALUES
(1, \x27admin\x27, \x27admin@blogcms.local\x27, \x27{admin_hash}\x27, \x27Quản Trị Viên\x27, \x27Quản trị viên toàn quyền hệ thống Blog/CMS DTC245180035.\x27, \x27admin\x27, true, NOW() - INTERVAL \x2790 days\x27),
(2, \x27tacgia01\x27, \x27tacgia01@blogcms.local\x27, \x27{author_hash}\x27, \x27Nguyễn Văn Tác\x27, \x27Kỹ sư phần mềm đam mê kiến trúc Microservices và phân tán.\x27, \x27author\x27, true, NOW() - INTERVAL \x2780 days\x27),
(3, \x27tacgia02\x27, \x27tacgia02@blogcms.local\x27, \x27{author_hash}\x27, \x27Trần Thị Bút\x27, \x27DevOps Engineer yêu thích tự động hóa, CI/CD và observability.\x27, \x27author\x27, true, NOW() - INTERVAL \x2775 days\x27),
(4, \x27docgia01\x27, \x27docgia01@blogcms.local\x27, \x27{member_hash}\x27, \x27Lê Độc Giả\x27, \x27Sinh viên năm cuối ngành Kỹ thuật Phần mềm.\x27, \x27member\x27, true, NOW() - INTERVAL \x2760 days\x27),
(5, \x27docgia02\x27, \x27docgia02@blogcms.local\x27, \x27{member_hash}\x27, \x27Phạm Đọc Sách\x27, \x27Độc giả yêu công nghệ và thích tìm hiểu các thủ thuật mới.\x27, \x27member\x27, true, NOW() - INTERVAL \x2750 days\x27)
ON CONFLICT (id) DO NOTHING;

SELECT setval(\x27users_id_seq\x27, 5);

INSERT INTO categories (id, name, slug, description, sort_order) VALUES
(1, \x27Công nghệ\x27, \x27cong-nghe\x27, \x27Tin tức, xu hướng và giải pháp công nghệ hiện đại.\x27, 1),
(2, \x27Lập trình\x27, \x27lap-trinh\x27, \x27Kỹ thuật viết mã sạch, giải thuật và phát triển phần mềm.\x27, 2),
(3, \x27DevOps & Hạ tầng\x27, \x27devops-ha-tang\x27, \x27Triển khai, tự động hóa, container và quản trị hạ tầng.\x27, 3),
(4, \x27Đời sống sinh viên\x27, \x27doi-song-sinh-vien\x27, \x27Kinh nghiệm học tập, thực tập và kỹ năng mềm sinh viên IT.\x27, 4),
(5, \x27Thủ thuật\x27, \x27thu-thuat\x27, \x27Mẹo tối ưu hiệu suất, cấu hình công cụ và giải quyết sự cố.\x27, 5)
ON CONFLICT (id) DO NOTHING;

SELECT setval(\x27categories_id_seq\x27, 5);

INSERT INTO tags (id, name, slug) VALUES
(1, \x27Docker\x27, \x27docker\x27),
(2, \x27Node.js\x27, \x27nodejs\x27),
(3, \x27PostgreSQL\x27, \x27postgresql\x27),
(4, \x27DevOps\x27, \x27devops\x27),
(5, \x27Bảo mật\x27, \x27bao-mat\x27),
(6, \x27Microservices\x27, \x27microservices\x27),
(7, \x27Sinh viên\x27, \x27sinh-vien\x27),
(8, \x27Clean Code\x27, \x27clean-code\x27),
(9, \x27Linux\x27, \x27linux\x27),
(10, \x27Monitoring\x27, \x27monitoring\x27)
ON CONFLICT (id) DO NOTHING;

SELECT setval(\x27tags_id_seq\x27, 10);
"""

with open(os.path.expanduser("~/blogcms/db/init.sql"), "w", newline="\n", encoding="utf-8") as f:
    f.write(sql)

print("Part 1: Schema and base tables created")
