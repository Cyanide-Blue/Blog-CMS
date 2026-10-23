const bcrypt = require('bcryptjs');
const db = require('../config/db');
const { logLoginSuccess, logLoginFailed } = require('../middleware/auth');

async function showLogin(req, res) {
  if (req.session?.user) {
    return res.redirect('/');
  }
  res.render('auth/login', {
    title: 'Đăng nhập - Blog/CMS',
    returnTo: req.query.returnTo || '',
    error: null
  });
}

async function login(req, res) {
  const { username, password, returnTo } = req.body;
  const trimmedUser = (username || '').trim();

  if (!trimmedUser || !password) {
    logLoginFailed(req, trimmedUser || 'unknown', 'unknown_user');
    return res.status(400).render('auth/login', {
      title: 'Đăng nhập - Blog/CMS',
      returnTo,
      error: 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.'
    });
  }

  try {
    const { rows } = await db.query(
      'SELECT id, username, email, password_hash, full_name, bio, role, is_active FROM users WHERE username = $1 OR email = $1',
      [trimmedUser]
    );

    if (rows.length === 0) {
      logLoginFailed(req, trimmedUser, 'unknown_user');
      return res.status(401).render('auth/login', {
        title: 'Đăng nhập - Blog/CMS',
        returnTo,
        error: 'Tên đăng nhập hoặc mật khẩu không chính xác.'
      });
    }

    const user = rows[0];

    if (!user.is_active) {
      logLoginFailed(req, user.username, 'inactive');
      return res.status(403).render('auth/login', {
        title: 'Đăng nhập - Blog/CMS',
        returnTo,
        error: 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.'
      });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      logLoginFailed(req, user.username, 'wrong_password');
      return res.status(401).render('auth/login', {
        title: 'Đăng nhập - Blog/CMS',
        returnTo,
        error: 'Tên đăng nhập hoặc mật khẩu không chính xác.'
      });
    }

    // Login successful
    logLoginSuccess(req, user.username);
    req.session.user = {
      id: user.id,
      username: user.username,
      email: user.email,
      full_name: user.full_name,
      role: user.role,
      is_active: user.is_active
    };

    if (returnTo && returnTo.startsWith('/')) {
      return res.redirect(returnTo);
    }

    if (user.role === 'admin') {
      return res.redirect('/admin/dashboard');
    } else if (user.role === 'author') {
      return res.redirect('/author/dashboard');
    }
    return res.redirect('/');
  } catch (err) {
    console.error('Error during login:', err);
    return res.status(500).render('auth/login', {
      title: 'Đăng nhập - Blog/CMS',
      returnTo,
      error: 'Có lỗi xảy ra trong quá trình xử lý, vui lòng thử lại sau.'
    });
  }
}

async function showRegister(req, res) {
  if (req.session?.user) {
    return res.redirect('/');
  }
  res.render('auth/register', {
    title: 'Đăng ký tài khoản - Blog/CMS',
    error: null,
    values: {}
  });
}

async function register(req, res) {
  const { username, email, full_name, password, confirm_password } = req.body;
  const values = { username, email, full_name };

  if (!username || !email || !full_name || !password) {
    return res.status(400).render('auth/register', {
      title: 'Đăng ký tài khoản - Blog/CMS',
      error: 'Vui lòng điền đầy đủ tất cả các trường thông tin.',
      values
    });
  }

  if (password.length < 8) {
    return res.status(400).render('auth/register', {
      title: 'Đăng ký tài khoản - Blog/CMS',
      error: 'Mật khẩu phải chứa ít nhất 8 ký tự.',
      values
    });
  }

  if (password !== confirm_password) {
    return res.status(400).render('auth/register', {
      title: 'Đăng ký tài khoản - Blog/CMS',
      error: 'Mật khẩu xác nhận không khớp.',
      values
    });
  }

  try {
    const existing = await db.query(
      'SELECT id, username, email FROM users WHERE username = $1 OR email = $2',
      [username.trim(), email.trim().toLowerCase()]
    );

    if (existing.rows.length > 0) {
      const match = existing.rows[0];
      const field = match.username === username.trim() ? 'Tên đăng nhập' : 'Địa chỉ email';
      return res.status(400).render('auth/register', {
        title: 'Đăng ký tài khoản - Blog/CMS',
        error: `${field} này đã được sử dụng. Vui lòng chọn thông tin khác.`,
        values
      });
    }

    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    const result = await db.query(
      `INSERT INTO users (username, email, password_hash, full_name, role, is_active)
       VALUES ($1, $2, $3, $4, 'member', true)
       RETURNING id, username, email, full_name, role, is_active`,
      [username.trim(), email.trim().toLowerCase(), passwordHash, full_name.trim()]
    );

    const newUser = result.rows[0];
    req.session.user = newUser;
    logLoginSuccess(req, newUser.username);

    return res.redirect('/?registered=1');
  } catch (err) {
    console.error('Error during registration:', err);
    return res.status(500).render('auth/register', {
      title: 'Đăng ký tài khoản - Blog/CMS',
      error: 'Có lỗi xảy ra khi tạo tài khoản. Vui lòng thử lại.',
      values
    });
  }
}

async function logout(req, res) {
  req.session.destroy((err) => {
    if (err) console.error('Error destroying session:', err);
    res.redirect('/');
  });
}

module.exports = {
  showLogin,
  login,
  showRegister,
  register,
  logout
};