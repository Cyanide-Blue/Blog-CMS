const fs = require('fs');
const path = require('path');
const db = require('../config/db');
const { generateUniqueSlug, toSlug } = require('../utils/slugify');
const { renderMarkdown } = require('../utils/markdown');
const { verifyMagicBytes } = require('../middleware/upload');
const { logPostStatus } = require('../middleware/auth');

async function getDashboard(req, res) {
  const user = req.session.user;
  const statusFilter = req.query.status || 'all';

  let query = `
    SELECT p.id, p.title, p.slug, p.status, p.view_count, p.review_note, p.published_at, p.updated_at,
           c.name AS category_name
    FROM posts p
    JOIN categories c ON c.id = p.category_id
    WHERE p.author_id = $1
  `;
  const params = [user.id];

  if (statusFilter !== 'all') {
    query += ' AND p.status = $2';
    params.push(statusFilter);
  }

  query += ' ORDER BY p.updated_at DESC';

  try {
    const { rows } = await db.query(query, params);

    // Counts by status for tabs
    const countRes = await db.query(`
      SELECT status, COUNT(*) AS count
      FROM posts
      WHERE author_id = $1
      GROUP BY status
    `, [user.id]);

    const counts = { all: 0, draft: 0, pending: 0, published: 0, rejected: 0, archived: 0 };
    for (const r of countRes.rows) {
      counts[r.status] = parseInt(r.count, 10);
      counts.all += counts[r.status];
    }

    res.render('author/dashboard', {
      title: 'Bàn làm việc Tác giả - Blog/CMS',
      posts: rows,
      statusFilter,
      counts
    });
  } catch (err) {
    console.error('Error in author getDashboard:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function showEditor(req, res) {
  const { id } = req.params;
  const user = req.session.user;

  try {
    const categoriesRes = await db.query('SELECT id, name FROM categories ORDER BY sort_order ASC, name ASC');
    let post = null;
    let tagString = '';

    if (id) {
      const postRes = await db.query('SELECT * FROM posts WHERE id = $1', [id]);
      if (postRes.rows.length === 0) {
        return res.status(404).render('errors/404', { title: '404', message: 'Bài viết không tồn tại.' });
      }
      post = postRes.rows[0];

      // Check ownership
      if (post.author_id !== user.id && user.role !== 'admin') {
        return res.status(403).render('errors/403', {
          title: '403 Forbidden',
          message: 'Bạn không có quyền chỉnh sửa bài viết của tác giả khác.'
        });
      }

      const tagsRes = await db.query(`
        SELECT t.name FROM tags t
        JOIN post_tags pt ON pt.tag_id = t.id
        WHERE pt.post_id = $1
      `, [post.id]);
      tagString = tagsRes.rows.map(t => t.name).join(', ');
    }

    res.render('author/editor', {
      title: post ? `Chỉnh sửa: ${post.title}` : 'Soạn bài viết mới',
      post,
      categories: categoriesRes.rows,
      tagString,
      error: null
    });
  } catch (err) {
    console.error('Error in showEditor:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function previewMarkdown(req, res) {
  const { content } = req.body;
  const html = renderMarkdown(content || '');
  res.json({ html });
}

async function handleTags(post_id, rawTags) {
  if (!rawTags) return;
  const tagNames = rawTags
    .split(',')
    .map(t => t.trim())
    .filter(t => t.length > 0)
    .slice(0, 5); // Max 5 tags

  await db.query('DELETE FROM post_tags WHERE post_id = $1', [post_id]);

  for (const name of tagNames) {
    const slug = toSlug(name);
    let tagRes = await db.query('SELECT id FROM tags WHERE slug = $1', [slug]);
    let tagId;
    if (tagRes.rows.length === 0) {
      const insertTag = await db.query(
        'INSERT INTO tags (name, slug) VALUES ($1, $2) ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name RETURNING id',
        [name, slug]
      );
      tagId = insertTag.rows[0].id;
    } else {
      tagId = tagRes.rows[0].id;
    }
    await db.query(
      'INSERT INTO post_tags (post_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [post_id, tagId]
    );
  }
}

async function savePost(req, res) {
  const user = req.session.user;
  const { id } = req.params;
  const { title, category_id, excerpt, content, tags, action } = req.body;

  if (!title || !category_id || !content) {
    const categoriesRes = await db.query('SELECT id, name FROM categories ORDER BY sort_order ASC, name ASC');
    return res.status(400).render('author/editor', {
      title: id ? 'Chỉnh sửa bài viết' : 'Soạn bài viết mới',
      post: { id, title, category_id, excerpt, content },
      categories: categoriesRes.rows,
      tagString: tags || '',
      error: 'Vui lòng điền đầy đủ tiêu đề, chuyên mục và nội dung bài viết.'
    });
  }

  let coverImagePath = null;
  if (req.file) {
    const verifiedMime = verifyMagicBytes(req.file.path);
    if (!verifiedMime) {
      fs.unlinkSync(req.file.path);
      const categoriesRes = await db.query('SELECT id, name FROM categories ORDER BY sort_order ASC, name ASC');
      return res.status(400).render('author/editor', {
        title: id ? 'Chỉnh sửa bài viết' : 'Soạn bài viết mới',
        post: { id, title, category_id, excerpt, content },
        categories: categoriesRes.rows,
        tagString: tags || '',
        error: 'Tệp tải lên không phải là ảnh hợp lệ (chữ ký nhị phân magic bytes không khớp).'
      });
    }

    coverImagePath = `/uploads/${req.file.filename}`;
    await db.query(
      `INSERT INTO media (uploaded_by, file_path, original_name, mime_type, size_bytes)
       VALUES ($1, $2, $3, $4, $5)`,
      [user.id, coverImagePath, req.file.originalname, verifiedMime, req.file.size]
    );
  }

  try {
    if (id) {
      // EDIT EXISTING POST
      const existingRes = await db.query('SELECT * FROM posts WHERE id = $1', [id]);
      if (existingRes.rows.length === 0) {
        return res.status(404).render('errors/404', { title: '404', message: 'Bài viết không tồn tại.' });
      }
      const existingPost = existingRes.rows[0];

      if (existingPost.author_id !== user.id && user.role !== 'admin') {
        return res.status(403).render('errors/403', {
          title: '403 Forbidden',
          message: 'Bạn không có quyền chỉnh sửa bài viết của tác giả khác.'
        });
      }

      // Workflow transition enforcement
      let newStatus = existingPost.status;
      if (action === 'submit_pending') {
        if (['draft', 'rejected', 'published'].includes(existingPost.status)) {
          newStatus = 'pending';
        }
      } else if (action === 'save_draft') {
        if (existingPost.status === 'draft') {
          newStatus = 'draft';
        } else if (existingPost.status === 'published' && user.role !== 'admin') {
          newStatus = 'pending'; // Author modifying published post drops to pending
        }
      } else if (action === 'publish_direct') {
        if (user.role === 'admin') {
          newStatus = 'published';
        } else {
          return res.status(403).json({ error: 'Tác giả không có quyền tự ý xuất bản bài viết.' });
        }
      } else {
        // Normal save
        if (existingPost.status === 'published' && user.role !== 'admin') {
          newStatus = 'pending'; // Re-review on edit
        }
      }

      const newSlug = await generateUniqueSlug(db, title, existingPost.id);
      const finalCover = coverImagePath || existingPost.cover_image_path;

      let publishedAt = existingPost.published_at;
      if (newStatus === 'published' && !publishedAt) {
        publishedAt = new Date();
      }

      await db.query(`
        UPDATE posts
        SET title = $1, slug = $2, category_id = $3, excerpt = $4, content = $5,
            cover_image_path = $6, status = $7, published_at = $8, updated_at = NOW()
        WHERE id = $9
      `, [title.trim(), newSlug, category_id, (excerpt || title).trim(), content, finalCover, newStatus, publishedAt, existingPost.id]);

      if (existingPost.status !== newStatus) {
        logPostStatus(req, user.username, existingPost.id, existingPost.status, newStatus);
      }

      await handleTags(existingPost.id, tags);
      return res.redirect('/author/dashboard');
    } else {
      // CREATE NEW POST
      const slug = await generateUniqueSlug(db, title);
      const finalCover = coverImagePath || '/images/covers/cover-1.svg';

      let targetStatus = 'draft';
      if (action === 'submit_pending') {
        targetStatus = 'pending';
      } else if (action === 'publish_direct' && user.role === 'admin') {
        targetStatus = 'published';
      } else if (action === 'publish_direct' && user.role !== 'admin') {
        return res.status(403).json({ error: 'Tác giả không thể tự xuất bản bài viết trực tiếp.' });
      }

      let publishedAt = targetStatus === 'published' ? new Date() : null;

      const insertRes = await db.query(`
        INSERT INTO posts (author_id, category_id, title, slug, excerpt, content, cover_image_path, status, published_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id
      `, [user.id, category_id, title.trim(), slug, (excerpt || title).trim(), content, finalCover, targetStatus, publishedAt]);

      const newPostId = insertRes.rows[0].id;
      logPostStatus(req, user.username, newPostId, 'none', targetStatus);

      await handleTags(newPostId, tags);
      return res.redirect('/author/dashboard');
    }
  } catch (err) {
    console.error('Error in savePost:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function deletePost(req, res) {
  const { id } = req.params;
  const user = req.session.user;

  try {
    const postRes = await db.query('SELECT * FROM posts WHERE id = $1', [id]);
    if (postRes.rows.length === 0) {
      return res.status(404).render('errors/404', { title: '404', message: 'Bài viết không tồn tại.' });
    }

    const post = postRes.rows[0];
    if (post.author_id !== user.id && user.role !== 'admin') {
      return res.status(403).render('errors/403', {
        title: '403 Forbidden',
        message: 'Bạn không có quyền xóa bài viết của tác giả khác.'
      });
    }

    await db.query('DELETE FROM posts WHERE id = $1', [id]);
    logPostStatus(req, user.username, id, post.status, 'deleted');

    return res.redirect('/author/dashboard');
  } catch (err) {
    console.error('Error in deletePost:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

module.exports = {
  getDashboard,
  showEditor,
  previewMarkdown,
  savePost,
  deletePost
};