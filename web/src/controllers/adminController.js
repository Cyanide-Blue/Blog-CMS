const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const db = require('../config/db');
const { toSlug } = require('../utils/slugify');
const { logPostStatus } = require('../middleware/auth');

// 1. KPI DASHBOARD
async function getDashboard(req, res) {
  try {
    const [kpiRes, topPostsRes, monthlyRes, categoryRes, authorRes] = await Promise.all([
      db.query(`
        SELECT
          (SELECT COUNT(*) FROM posts WHERE status = 'published') AS total_published,
          (SELECT COUNT(*) FROM posts WHERE status = 'pending') AS total_pending,
          (SELECT COUNT(*) FROM comments WHERE created_at >= NOW() - INTERVAL '7 days') AS comments_7days,
          (SELECT COALESCE(SUM(view_count), 0) FROM posts) AS total_views
      `),
      db.query(`
        SELECT id, title, slug, view_count, published_at
        FROM posts
        WHERE status = 'published'
        ORDER BY view_count DESC
        LIMIT 10
      `),
      db.query(`
        SELECT TO_CHAR(published_at, 'YYYY-MM') AS month_label, COUNT(*) AS count
        FROM posts
        WHERE status = 'published' AND published_at IS NOT NULL
        GROUP BY month_label
        ORDER BY month_label ASC
        LIMIT 6
      `),
      db.query(`
        SELECT c.name, COUNT(p.id) AS post_count
        FROM categories c
        LEFT JOIN posts p ON p.category_id = c.id
        GROUP BY c.id
        ORDER BY post_count DESC
      `),
      db.query(`
        SELECT u.username, u.full_name, COUNT(p.id) AS post_count
        FROM users u
        LEFT JOIN posts p ON p.author_id = u.id
        WHERE u.role IN ('author', 'admin')
        GROUP BY u.id
        ORDER BY post_count DESC
      `)
    ]);

    const kpi = kpiRes.rows[0];

    res.render('admin/dashboard', {
      title: 'Dashboard KPI Quản trị - Blog/CMS',
      kpi,
      topPosts: topPostsRes.rows,
      monthlyStats: monthlyRes.rows,
      categoryStats: categoryRes.rows,
      authorStats: authorRes.rows
    });
  } catch (err) {
    console.error('Error in admin getDashboard:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

// 2. APPROVAL QUEUE & POST WORKFLOW
async function getQueue(req, res) {
  const statusFilter = req.query.status || 'pending';

  try {
    let query = `
      SELECT p.id, p.title, p.slug, p.status, p.review_note, p.created_at, p.updated_at,
             u.username AS author_username, u.full_name AS author_name,
             c.name AS category_name
      FROM posts p
      JOIN users u ON u.id = p.author_id
      JOIN categories c ON c.id = p.category_id
    `;
    const params = [];

    if (statusFilter !== 'all') {
      query += ' WHERE p.status = $1';
      params.push(statusFilter);
    }

    query += ' ORDER BY p.updated_at DESC';

    const { rows } = await db.query(query, params);

    const countsRes = await db.query(`
      SELECT status, COUNT(*) AS count
      FROM posts
      GROUP BY status
    `);
    const counts = { pending: 0, published: 0, rejected: 0, draft: 0, archived: 0 };
    for (const r of countsRes.rows) {
      counts[r.status] = parseInt(r.count, 10);
    }

    res.render('admin/queue', {
      title: 'Hàng đợi duyệt bài - Blog/CMS',
      posts: rows,
      statusFilter,
      counts,
      message: req.query.msg || null,
      error: req.query.err || null
    });
  } catch (err) {
    console.error('Error in getQueue:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function updatePostStatus(req, res) {
  const { id } = req.params;
  const { action, review_note } = req.body;
  const adminUser = req.session.user;

  try {
    const postRes = await db.query('SELECT * FROM posts WHERE id = $1', [id]);
    if (postRes.rows.length === 0) {
      return res.status(404).render('errors/404', { title: '404', message: 'Bài viết không tồn tại.' });
    }

    const post = postRes.rows[0];
    let targetStatus = post.status;
    let publishedAt = post.published_at;
    let note = post.review_note;

    if (action === 'publish') {
      // pending or archived or draft -> published
      targetStatus = 'published';
      publishedAt = new Date();
      note = null;
    } else if (action === 'reject') {
      if (!review_note || review_note.trim().length === 0) {
        return res.redirect(`/admin/queue?status=pending&err=${encodeURIComponent('Từ chối bài viết bắt buộc phải có lý do (review note).')}`);
      }
      targetStatus = 'rejected';
      note = review_note.trim();
    } else if (action === 'archive') {
      if (post.status !== 'published') {
        return res.redirect(`/admin/queue?status=published&err=${encodeURIComponent('Chỉ có thể lưu trữ bài viết đang xuất bản.')}`);
      }
      targetStatus = 'archived';
    } else if (action === 'restore') {
      if (post.status !== 'archived') {
        return res.redirect(`/admin/queue?status=archived&err=${encodeURIComponent('Chỉ có thể khôi phục bài viết đang lưu trữ.')}`);
      }
      targetStatus = 'published';
    } else {
      return res.status(400).redirect(`/admin/queue?err=${encodeURIComponent('Hành động không hợp lệ.')}`);
    }

    await db.query(`
      UPDATE posts
      SET status = $1, published_at = $2, review_note = $3, updated_at = NOW()
      WHERE id = $4
    `, [targetStatus, publishedAt, note, id]);

    logPostStatus(req, adminUser.username, id, post.status, targetStatus);

    return res.redirect(`/admin/queue?status=${targetStatus}&msg=${encodeURIComponent(`Đã cập nhật trạng thái bài viết thành [${targetStatus}].`)}`);
  } catch (err) {
    console.error('Error updating post status:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

// 3. CATEGORIES CRUD
async function getCategories(req, res) {
  try {
    const { rows } = await db.query(`
      SELECT c.id, c.name, c.slug, c.description, c.sort_order, COUNT(p.id) AS post_count
      FROM categories c
      LEFT JOIN posts p ON p.category_id = c.id
      GROUP BY c.id
      ORDER BY c.sort_order ASC, c.name ASC
    `);

    res.render('admin/categories', {
      title: 'Quản lý Chuyên mục - Blog/CMS',
      categories: rows,
      error: req.query.err || null,
      msg: req.query.msg || null
    });
  } catch (err) {
    console.error('Error in getCategories:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function createCategory(req, res) {
  const { name, description, sort_order } = req.body;
  if (!name || name.trim().length === 0) {
    return res.redirect(`/admin/categories?err=${encodeURIComponent('Tên chuyên mục không được để trống.')}`);
  }

  const slug = toSlug(name);
  try {
    await db.query(
      `INSERT INTO categories (name, slug, description, sort_order)
       VALUES ($1, $2, $3, $4)`,
      [name.trim(), slug, description || '', parseInt(sort_order, 10) || 0]
    );
    return res.redirect(`/admin/categories?msg=${encodeURIComponent('Tạo chuyên mục mới thành công.')}`);
  } catch (err) {
    if (err.code === '23505') {
      return res.redirect(`/admin/categories?err=${encodeURIComponent('Tên hoặc slug chuyên mục đã tồn tại.')}`);
    }
    console.error('Error creating category:', err);
    return res.redirect(`/admin/categories?err=${encodeURIComponent('Lỗi máy chủ khi tạo chuyên mục.')}`);
  }
}

async function deleteCategory(req, res) {
  const { id } = req.params;

  try {
    const checkPosts = await db.query('SELECT COUNT(*) AS count FROM posts WHERE category_id = $1', [id]);
    const postCount = parseInt(checkPosts.rows[0].count, 10);

    if (postCount > 0) {
      return res.redirect(`/admin/categories?err=${encodeURIComponent(`Không thể xóa chuyên mục này vì đang có ${postCount} bài viết trực thuộc.`)}`);
    }

    await db.query('DELETE FROM categories WHERE id = $1', [id]);
    return res.redirect(`/admin/categories?msg=${encodeURIComponent('Đã xóa chuyên mục thành công.')}`);
  } catch (err) {
    console.error('Error deleting category:', err);
    return res.redirect(`/admin/categories?err=${encodeURIComponent('Lỗi máy chủ khi xóa chuyên mục.')}`);
  }
}

// 4. TAGS CRUD
async function getTags(req, res) {
  try {
    const { rows } = await db.query(`
      SELECT t.id, t.name, t.slug, COUNT(pt.post_id) AS post_count
      FROM tags t
      LEFT JOIN post_tags pt ON pt.tag_id = t.id
      GROUP BY t.id
      ORDER BY post_count DESC, t.name ASC
    `);

    res.render('admin/tags', {
      title: 'Quản lý Thẻ (Tags) - Blog/CMS',
      tags: rows,
      error: req.query.err || null,
      msg: req.query.msg || null
    });
  } catch (err) {
    console.error('Error in getTags:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function createTag(req, res) {
  const { name } = req.body;
  if (!name || name.trim().length === 0) {
    return res.redirect(`/admin/tags?err=${encodeURIComponent('Tên thẻ không được để trống.')}`);
  }

  const slug = toSlug(name);
  try {
    await db.query('INSERT INTO tags (name, slug) VALUES ($1, $2)', [name.trim(), slug]);
    return res.redirect(`/admin/tags?msg=${encodeURIComponent('Tạo thẻ mới thành công.')}`);
  } catch (err) {
    if (err.code === '23505') {
      return res.redirect(`/admin/tags?err=${encodeURIComponent('Thẻ này đã tồn tại.')}`);
    }
    return res.redirect(`/admin/tags?err=${encodeURIComponent('Lỗi khi tạo thẻ mới.')}`);
  }
}

async function deleteTag(req, res) {
  const { id } = req.params;
  try {
    await db.query('DELETE FROM tags WHERE id = $1', [id]);
    return res.redirect(`/admin/tags?msg=${encodeURIComponent('Đã xóa thẻ thành công.')}`);
  } catch (err) {
    console.error('Error deleting tag:', err);
    return res.redirect(`/admin/tags?err=${encodeURIComponent('Lỗi khi xóa thẻ.')}`);
  }
}

// 5. COMMENTS MODERATION
async function getComments(req, res) {
  try {
    const { rows } = await db.query(`
      SELECT c.id, c.content, c.status, c.created_at,
             u.username, u.full_name,
             p.title AS post_title, p.slug AS post_slug
      FROM comments c
      JOIN users u ON u.id = c.user_id
      JOIN posts p ON p.id = c.post_id
      ORDER BY c.created_at DESC
      LIMIT 100
    `);

    res.render('admin/comments', {
      title: 'Kiểm duyệt Bình luận - Blog/CMS',
      comments: rows,
      msg: req.query.msg || null
    });
  } catch (err) {
    console.error('Error in getComments:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

// 6. USERS MANAGEMENT
async function getUsers(req, res) {
  try {
    const { rows } = await db.query(`
      SELECT u.id, u.username, u.email, u.full_name, u.role, u.is_active, u.created_at,
             COUNT(p.id) AS post_count
      FROM users u
      LEFT JOIN posts p ON p.author_id = u.id
      GROUP BY u.id
      ORDER BY u.created_at ASC
    `);

    res.render('admin/users', {
      title: 'Quản lý Tài khoản - Blog/CMS',
      users: rows,
      error: req.query.err || null,
      msg: req.query.msg || null
    });
  } catch (err) {
    console.error('Error in getUsers:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function createUser(req, res) {
  const { username, email, full_name, role, password } = req.body;
  if (!username || !email || !full_name || !password) {
    return res.redirect(`/admin/users?err=${encodeURIComponent('Vui lòng điền đầy đủ thông tin.')}`);
  }

  try {
    const passwordHash = await bcrypt.hash(password, 10);
    await db.query(
      `INSERT INTO users (username, email, full_name, role, password_hash, is_active)
       VALUES ($1, $2, $3, $4, $5, true)`,
      [username.trim(), email.trim().toLowerCase(), full_name.trim(), role || 'member', passwordHash]
    );
    return res.redirect(`/admin/users?msg=${encodeURIComponent(`Đã tạo tài khoản [${username}] thành công.`)}`);
  } catch (err) {
    if (err.code === '23505') {
      return res.redirect(`/admin/users?err=${encodeURIComponent('Tên người dùng hoặc email đã tồn tại.')}`);
    }
    console.error('Error creating user:', err);
    return res.redirect(`/admin/users?err=${encodeURIComponent('Lỗi máy chủ khi tạo tài khoản.')}`);
  }
}

async function updateUserRole(req, res) {
  const { id } = req.params;
  const { role } = req.body;
  const adminUser = req.session.user;

  if (parseInt(id, 10) === adminUser.id && role !== 'admin') {
    return res.redirect(`/admin/users?err=${encodeURIComponent('Không được phép tự hạ quyền tài khoản của chính mình.')}`);
  }

  try {
    await db.query('UPDATE users SET role = $1 WHERE id = $2', [role, id]);
    return res.redirect(`/admin/users?msg=${encodeURIComponent('Cập nhật vai trò thành công.')}`);
  } catch (err) {
    console.error('Error updating role:', err);
    return res.redirect(`/admin/users?err=${encodeURIComponent('Lỗi khi cập nhật vai trò.')}`);
  }
}

async function toggleUserActive(req, res) {
  const { id } = req.params;
  const adminUser = req.session.user;

  if (parseInt(id, 10) === adminUser.id) {
    return res.redirect(`/admin/users?err=${encodeURIComponent('Không được phép tự khóa tài khoản của chính mình.')}`);
  }

  try {
    const userRes = await db.query('SELECT is_active FROM users WHERE id = $1', [id]);
    if (userRes.rows.length === 0) {
      return res.redirect(`/admin/users?err=${encodeURIComponent('Không tìm thấy tài khoản.')}`);
    }

    const currentActive = userRes.rows[0].is_active;
    const newActive = !currentActive;
    await db.query('UPDATE users SET is_active = $1 WHERE id = $2', [newActive, id]);

    const statusText = newActive ? 'mở khóa' : 'khóa';
    return res.redirect(`/admin/users?msg=${encodeURIComponent(`Đã ${statusText} tài khoản thành công.`)}`);
  } catch (err) {
    console.error('Error toggling active:', err);
    return res.redirect(`/admin/users?err=${encodeURIComponent('Lỗi khi cập nhật trạng thái tài khoản.')}`);
  }
}

// 7. MEDIA LIBRARY
async function getMedia(req, res) {
  try {
    const { rows } = await db.query(`
      SELECT m.id, m.file_path, m.original_name, m.mime_type, m.size_bytes, m.created_at,
             u.username AS uploader_username,
             EXISTS(SELECT 1 FROM posts WHERE cover_image_path = m.file_path OR content LIKE '%' || m.file_path || '%') AS is_used
      FROM media m
      JOIN users u ON u.id = m.uploaded_by
      ORDER BY m.created_at DESC
    `);

    res.render('admin/media', {
      title: 'Thư viện Media - Blog/CMS',
      mediaList: rows,
      error: req.query.err || null,
      msg: req.query.msg || null
    });
  } catch (err) {
    console.error('Error in getMedia:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function deleteMedia(req, res) {
  const { id } = req.params;

  try {
    const mediaRes = await db.query('SELECT * FROM media WHERE id = $1', [id]);
    if (mediaRes.rows.length === 0) {
      return res.redirect(`/admin/media?err=${encodeURIComponent('Tệp không tồn tại.')}`);
    }

    const media = mediaRes.rows[0];

    // Check if in use
    const checkUsed = await db.query(
      "SELECT id FROM posts WHERE cover_image_path = $1 OR content LIKE '%' || $1 || '%'",
      [media.file_path]
    );

    if (checkUsed.rows.length > 0) {
      return res.redirect(`/admin/media?err=${encodeURIComponent('Tệp đang được bài viết sử dụng, không thể xóa.')}`);
    }

    // Delete record
    await db.query('DELETE FROM media WHERE id = $1', [id]);

    // Unlink file if it exists in uploads
    const filename = path.basename(media.file_path);
    const diskPath = path.join(__dirname, '../../public/uploads', filename);
    if (fs.existsSync(diskPath)) {
      fs.unlinkSync(diskPath);
    }

    return res.redirect(`/admin/media?msg=${encodeURIComponent('Đã xóa tệp media thành công.')}`);
  } catch (err) {
    console.error('Error deleting media:', err);
    return res.redirect(`/admin/media?err=${encodeURIComponent('Lỗi khi xóa tệp media.')}`);
  }
}

module.exports = {
  getDashboard,
  getQueue,
  updatePostStatus,
  getCategories,
  createCategory,
  deleteCategory,
  getTags,
  createTag,
  deleteTag,
  getComments,
  getUsers,
  createUser,
  updateUserRole,
  toggleUserActive,
  getMedia,
  deleteMedia
};