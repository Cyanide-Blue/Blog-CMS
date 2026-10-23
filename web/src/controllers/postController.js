const db = require('../config/db');
const { renderMarkdown } = require('../utils/markdown');
const { generateRssXml } = require('../utils/rss');

async function getCategoriesAndTags() {
  const [catRes, tagRes] = await Promise.all([
    db.query(`
      SELECT c.id, c.name, c.slug, c.description, COUNT(p.id) AS post_count
      FROM categories c
      LEFT JOIN posts p ON p.category_id = c.id AND p.status = 'published' AND p.published_at <= NOW()
      GROUP BY c.id ORDER BY c.sort_order ASC, c.name ASC
    `),
    db.query(`
      SELECT t.id, t.name, t.slug, COUNT(pt.post_id) AS post_count
      FROM tags t
      LEFT JOIN post_tags pt ON pt.tag_id = t.id
      LEFT JOIN posts p ON p.id = pt.post_id AND p.status = 'published' AND p.published_at <= NOW()
      GROUP BY t.id ORDER BY post_count DESC, t.name ASC LIMIT 20
    `)
  ]);
  return {
    categories: catRes.rows,
    tags: tagRes.rows
  };
}

async function getHome(req, res) {
  try {
    const [latestRes, popularRes, meta] = await Promise.all([
      db.query(`
        SELECT p.id, p.title, p.slug, p.excerpt, p.cover_image_path, p.view_count, p.published_at,
               u.username AS author_username, u.full_name AS author_name,
               c.name AS category_name, c.slug AS category_slug
        FROM posts p
        JOIN users u ON u.id = p.author_id
        JOIN categories c ON c.id = p.category_id
        WHERE p.status = 'published' AND p.published_at <= NOW()
        ORDER BY p.published_at DESC
        LIMIT 6
      `),
      db.query(`
        SELECT p.id, p.title, p.slug, p.excerpt, p.cover_image_path, p.view_count, p.published_at,
               u.username AS author_username, u.full_name AS author_name,
               c.name AS category_name, c.slug AS category_slug
        FROM posts p
        JOIN users u ON u.id = p.author_id
        JOIN categories c ON c.id = p.category_id
        WHERE p.status = 'published' AND p.published_at <= NOW()
        ORDER BY p.view_count DESC
        LIMIT 4
      `),
      getCategoriesAndTags()
    ]);

    res.render('home', {
      title: 'Trang chủ - Hệ thống Blog / CMS',
      latestPosts: latestRes.rows,
      popularPosts: popularRes.rows,
      categories: meta.categories,
      tags: meta.tags,
      registered: req.query.registered === '1'
    });
  } catch (err) {
    console.error('Error in getHome:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function getPosts(req, res) {
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = 10;
  const offset = (page - 1) * limit;

  const categorySlug = req.query.category || '';
  const tagSlug = req.query.tag || '';
  const search = req.query.q ? req.query.q.trim() : '';
  const sort = req.query.sort || 'latest';

  let whereClauses = ["p.status = 'published'", "p.published_at <= NOW()"];
  let params = [];
  let paramIdx = 1;

  if (categorySlug) {
    whereClauses.push(`c.slug = $${paramIdx}`);
    params.push(categorySlug);
    paramIdx++;
  }

  if (tagSlug) {
    whereClauses.push(`EXISTS (
      SELECT 1 FROM post_tags pt_sub
      JOIN tags t_sub ON t_sub.id = pt_sub.tag_id
      WHERE pt_sub.post_id = p.id AND t_sub.slug = $${paramIdx}
    )`);
    params.push(tagSlug);
    paramIdx++;
  }

  if (search) {
    const escapedSearch = search.replace(/[%_\\]/g, '\\$&');
    whereClauses.push(`(
      p.title ILIKE '%' || $${paramIdx} || '%' ESCAPE '\\' OR
      p.excerpt ILIKE '%' || $${paramIdx} || '%' ESCAPE '\\' OR
      p.content ILIKE '%' || $${paramIdx} || '%' ESCAPE '\\'
    )`);
    params.push(escapedSearch);
    paramIdx++;
  }

  let orderBy = 'p.published_at DESC';
  if (sort === 'views') {
    orderBy = 'p.view_count DESC, p.published_at DESC';
  } else if (sort === 'title') {
    orderBy = 'p.title ASC';
  }

  const whereSql = whereClauses.join(' AND ');

  try {
    const countQuery = `
      SELECT COUNT(DISTINCT p.id) AS total
      FROM posts p
      JOIN categories c ON c.id = p.category_id
      WHERE ${whereSql}
    `;
    const countRes = await db.query(countQuery, params);
    const totalPosts = parseInt(countRes.rows[0].total, 10) || 0;
    const totalPages = Math.ceil(totalPosts / limit) || 1;

    const listQuery = `
      SELECT p.id, p.title, p.slug, p.excerpt, p.cover_image_path, p.view_count, p.published_at,
             u.username AS author_username, u.full_name AS author_name,
             c.name AS category_name, c.slug AS category_slug,
             COALESCE(
               (SELECT json_agg(json_build_object('name', t.name, 'slug', t.slug))
                FROM tags t JOIN post_tags pt ON pt.tag_id = t.id WHERE pt.post_id = p.id), '[]'
             ) AS tags
      FROM posts p
      JOIN users u ON u.id = p.author_id
      JOIN categories c ON c.id = p.category_id
      WHERE ${whereSql}
      ORDER BY ${orderBy}
      LIMIT ${limit} OFFSET ${offset}
    `;
    const listRes = await db.query(listQuery, params);
    const meta = await getCategoriesAndTags();

    res.render('posts/index', {
      title: 'Danh sách bài viết - Blog/CMS',
      posts: listRes.rows,
      currentPage: page,
      totalPages,
      totalPosts,
      categorySlug,
      tagSlug,
      search,
      sort,
      categories: meta.categories,
      tags: meta.tags
    });
  } catch (err) {
    console.error('Error in getPosts:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function getPostDetail(req, res) {
  const { slug } = req.params;

  try {
    const postRes = await db.query(`
      SELECT p.*,
             u.username AS author_username, u.full_name AS author_name, u.bio AS author_bio,
             c.name AS category_name, c.slug AS category_slug
      FROM posts p
      JOIN users u ON u.id = p.author_id
      JOIN categories c ON c.id = p.category_id
      WHERE p.slug = $1
    `, [slug]);

    if (postRes.rows.length === 0) {
      return res.status(404).render('errors/404', {
        title: '404 - Không tìm thấy bài viết',
        message: 'Bài viết bạn yêu cầu không tồn tại hoặc đã bị gỡ bỏ.'
      });
    }

    const post = postRes.rows[0];
    const currentUser = req.session?.user;
    const isAuthor = currentUser && currentUser.id === post.author_id;
    const isAdmin = currentUser && currentUser.role === 'admin';

    // Access control: only author or admin can view non-published posts
    const isPubliclyAvailable = post.status === 'published' && post.published_at && new Date(post.published_at) <= new Date();
    if (!isPubliclyAvailable && !isAuthor && !isAdmin) {
      return res.status(404).render('errors/404', {
        title: '404 - Không tìm thấy bài viết',
        message: 'Bài viết này hiện chưa được xuất bản hoặc đang chờ duyệt.'
      });
    }

    // View count increment: at most once per session per post; do not count if author views own post
    if (isPubliclyAvailable && !isAuthor) {
      req.session.viewedPosts = req.session.viewedPosts || [];
      if (!req.session.viewedPosts.includes(post.id)) {
        req.session.viewedPosts.push(post.id);
        await db.query('UPDATE posts SET view_count = view_count + 1 WHERE id = $1', [post.id]);
        post.view_count += 1;
      }
    }

    // Render markdown to sanitized HTML
    post.renderedContent = renderMarkdown(post.content);

    // Get post tags
    const tagsRes = await db.query(`
      SELECT t.id, t.name, t.slug
      FROM tags t
      JOIN post_tags pt ON pt.tag_id = t.id
      WHERE pt.post_id = $1
    `, [post.id]);
    post.tags = tagsRes.rows;

    // Related posts (same category, published, limit 3)
    const relatedRes = await db.query(`
      SELECT id, title, slug, excerpt, cover_image_path, published_at, view_count
      FROM posts
      WHERE category_id = $1 AND id != $2 AND status = 'published' AND published_at <= NOW()
      ORDER BY published_at DESC
      LIMIT 3
    `, [post.category_id, post.id]);

    // Comments
    const commentsRes = await db.query(`
      SELECT c.id, c.parent_id, c.content, c.status, c.created_at,
             u.id AS user_id, u.username, u.full_name, u.role
      FROM comments c
      JOIN users u ON u.id = c.user_id
      WHERE c.post_id = $1
      ORDER BY c.created_at ASC
    `, [post.id]);

    // Build hierarchical comments (1-level reply)
    const rawComments = commentsRes.rows;
    const parentComments = [];
    const repliesMap = {};

    for (const c of rawComments) {
      if (!c.parent_id) {
        parentComments.push(c);
      } else {
        if (!repliesMap[c.parent_id]) {
          repliesMap[c.parent_id] = [];
        }
        repliesMap[c.parent_id].push(c);
      }
    }

    res.render('posts/show', {
      title: `${post.title} - Blog/CMS`,
      post,
      relatedPosts: relatedRes.rows,
      parentComments,
      repliesMap,
      isAuthor,
      isAdmin,
      commentError: req.query.commentError || null
    });
  } catch (err) {
    console.error('Error in getPostDetail:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function getAuthorProfile(req, res) {
  const { username } = req.params;

  try {
    const userRes = await db.query(
      'SELECT id, username, full_name, bio, role, created_at FROM users WHERE username = $1',
      [username]
    );

    if (userRes.rows.length === 0) {
      return res.status(404).render('errors/404', {
        title: '404 - Không tìm thấy tác giả',
        message: 'Tác giả bạn tìm kiếm không tồn tại trên hệ thống.'
      });
    }

    const author = userRes.rows[0];

    const postsRes = await db.query(`
      SELECT p.id, p.title, p.slug, p.excerpt, p.cover_image_path, p.view_count, p.published_at,
             c.name AS category_name, c.slug AS category_slug
      FROM posts p
      JOIN categories c ON c.id = p.category_id
      WHERE p.author_id = $1 AND p.status = 'published' AND p.published_at <= NOW()
      ORDER BY p.published_at DESC
    `, [author.id]);

    res.render('authors/show', {
      title: `Tác giả ${author.full_name} - Blog/CMS`,
      author,
      posts: postsRes.rows
    });
  } catch (err) {
    console.error('Error in getAuthorProfile:', err);
    res.status(500).render('errors/500', { title: '500 Server Error', error: err.message });
  }
}

async function getRssFeed(req, res) {
  try {
    const { rows } = await db.query(`
      SELECT p.title, p.slug, p.excerpt, p.published_at,
             u.full_name AS author_name, c.name AS category_name
      FROM posts p
      JOIN users u ON u.id = p.author_id
      JOIN categories c ON c.id = p.category_id
      WHERE p.status = 'published' AND p.published_at <= NOW()
      ORDER BY p.published_at DESC
      LIMIT 20
    `);

    const protocol = req.headers['x-forwarded-proto'] || req.protocol || 'http';
    const host = req.get('host') || 'localhost:3000';
    const baseUrl = `${protocol}://${host}`;

    const xml = generateRssXml(rows, baseUrl);
    res.set('Content-Type', 'application/xml; charset=utf-8').send(xml);
  } catch (err) {
    console.error('Error generating RSS:', err);
    res.status(500).send('Error generating RSS feed');
  }
}

module.exports = {
  getHome,
  getPosts,
  getPostDetail,
  getAuthorProfile,
  getRssFeed
};