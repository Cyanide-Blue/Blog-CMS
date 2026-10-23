const crypto = require('crypto');

function csrfMiddleware(req, res, next) {
  if (!req.session) {
    return next();
  }

  // Generate token if not already exists in session
  if (!req.session.csrfToken) {
    req.session.csrfToken = crypto.randomBytes(24).toString('hex');
  }

  // Make available to all views via res.locals
  res.locals.csrfToken = req.session.csrfToken;

  // Safe HTTP methods do not require CSRF verification
  const safeMethods = ['GET', 'HEAD', 'OPTIONS'];
  if (safeMethods.includes(req.method)) {
    return next();
  }

  // Verify token on state-changing requests
  const submittedToken =
    req.body?._csrf ||
    req.query?._csrf ||
    req.headers['x-csrf-token'] ||
    req.headers['csrf-token'];

  if (!submittedToken || submittedToken !== req.session.csrfToken) {
    if (req.xhr || req.headers.accept?.includes('json')) {
      return res.status(403).json({ error: 'CSRF token không hợp lệ hoặc đã hết hạn.' });
    }
    return res.status(403).render('errors/403', {
      title: 'Lỗi bảo mật (403 CSRF)',
      message: 'Yêu cầu của bạn bị từ chối do mã kiểm tra CSRF không khớp hoặc phiên đã hết hạn. Vui lòng tải lại trang và thử lại.'
    });
  }

  next();
}

module.exports = csrfMiddleware;