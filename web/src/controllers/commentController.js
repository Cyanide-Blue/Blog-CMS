const db = require('../config/db');

async function createComment(req, res) {
  const { post_id, parent_id, content, return_slug } = req.body;
  const user = req.session.user;

  if (!content || content.trim().length === 0) {
    return res.redirect(`/posts/${return_slug}?commentError=${encodeURIComponent('Nội dung bình luận không được để trống.')}#comment-form`);
  }

  const trimmedContent = content.trim();
  if (trimmedContent.length > 1000) {
    return res.redirect(`/posts/${return_slug}?commentError=${encodeURIComponent('Nội dung bình luận vượt quá 1000 ký tự cho phép.')}#comment-form`);
  }

  try {
    // 1. Anti-spam check: Max 5 comments per minute per user
    const rateCheck = await db.query(
      `SELECT COUNT(*) AS recent_count FROM comments
       WHERE user_id = $1 AND created_at > NOW() - INTERVAL '1 minute'`,
      [user.id]
    );

    const recentCount = parseInt(rateCheck.rows[0].recent_count, 10);
    if (recentCount >= 5) {
      if (req.xhr || req.headers.accept?.includes('json')) {
        return res.status(429).json({
          error: 'Bạn đang gửi bình luận quá nhanh. Tối đa 5 bình luận mỗi phút. Vui lòng thử lại sau.'
        });
      }
      return res.status(429).redirect(
        `/posts/${return_slug}?commentError=${encodeURIComponent('Bạn đang gửi bình luận quá nhanh. Giới hạn 5 bình luận/phút. Vui lòng chờ giây lát rồi thử lại.')}#comment-form`
      );
    }

    // 2. Validate post exists and is published
    const postRes = await db.query('SELECT id, slug, status FROM posts WHERE id = $1', [post_id]);
    if (postRes.rows.length === 0) {
      return res.status(404).render('errors/404', { title: '404', message: 'Bài viết không tồn tại.' });
    }

    // 3. One-level reply check
    let validParentId = null;
    if (parent_id) {
      const parentRes = await db.query(
        'SELECT id, post_id, parent_id FROM comments WHERE id = $1',
        [parent_id]
      );
      if (parentRes.rows.length > 0) {
        const parent = parentRes.rows[0];
        if (parent.post_id == post_id) {
          // If parent is already a reply, attach to root comment (1-level reply constraint)
          validParentId = parent.parent_id ? parent.parent_id : parent.id;
        }
      }
    }

    const insertRes = await db.query(
      `INSERT INTO comments (post_id, user_id, parent_id, content, status)
       VALUES ($1, $2, $3, $4, 'approved')
       RETURNING id`,
      [post_id, user.id, validParentId, trimmedContent]
    );

    const newCommentId = insertRes.rows[0].id;
    return res.redirect(`/posts/${return_slug}#comment-${newCommentId}`);
  } catch (err) {
    console.error('Error creating comment:', err);
    return res.status(500).redirect(
      `/posts/${return_slug}?commentError=${encodeURIComponent('Đã xảy ra lỗi khi đăng bình luận.')}#comment-form`
    );
  }
}

async function deleteComment(req, res) {
  const { id } = req.params;
  const user = req.session.user;
  const returnUrl = req.body.return_url || req.headers.referer || '/';

  try {
    const commentRes = await db.query('SELECT * FROM comments WHERE id = $1', [id]);
    if (commentRes.rows.length === 0) {
      return res.status(404).render('errors/404', { title: '404', message: 'Bình luận không tồn tại.' });
    }

    const comment = commentRes.rows[0];
    const isOwner = comment.user_id === user.id;
    const isAdmin = user.role === 'admin';

    if (!isOwner && !isAdmin) {
      return res.status(403).render('errors/403', {
        title: '403 Forbidden',
        message: 'Bạn không có quyền xóa bình luận này.'
      });
    }

    await db.query('DELETE FROM comments WHERE id = $1', [id]);
    return res.redirect(returnUrl);
  } catch (err) {
    console.error('Error deleting comment:', err);
    return res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function toggleCommentStatus(req, res) {
  const { id } = req.params;
  const user = req.session.user;
  const returnUrl = req.body.return_url || req.headers.referer || '/';

  try {
    const commentRes = await db.query(`
      SELECT c.*, p.author_id AS post_author_id
      FROM comments c
      JOIN posts p ON p.id = c.post_id
      WHERE c.id = $1
    `, [id]);

    if (commentRes.rows.length === 0) {
      return res.status(404).render('errors/404', { title: '404', message: 'Bình luận không tồn tại.' });
    }

    const comment = commentRes.rows[0];
    const isPostAuthor = comment.post_author_id === user.id;
    const isAdmin = user.role === 'admin';

    if (!isPostAuthor && !isAdmin) {
      return res.status(403).render('errors/403', {
        title: '403 Forbidden',
        message: 'Bạn không có quyền ẩn hoặc hiện bình luận này.'
      });
    }

    const newStatus = comment.status === 'approved' ? 'hidden' : 'approved';
    await db.query('UPDATE comments SET status = $1 WHERE id = $2', [newStatus, id]);

    return res.redirect(returnUrl);
  } catch (err) {
    console.error('Error toggling comment status:', err);
    return res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

module.exports = {
  createComment,
  deleteComment,
  toggleCommentStatus
};