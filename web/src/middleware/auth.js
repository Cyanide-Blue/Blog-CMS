function extractClientIp(req) {
  const xForwardedFor = req.headers['x-forwarded-for'];
  if (xForwardedFor) {
    const ips = xForwardedFor.split(',');
    return ips[0].trim();
  }
  return req.socket.remoteAddress || req.ip || '127.0.0.1';
}

function logLoginSuccess(req, username) {
  const ip = extractClientIp(req);
  const ts = new Date().toISOString();
  console.log(`[AUTH_OK] timestamp=${ts} ip=${ip} user=${username} LOGIN_SUCCESS`);
}

function logLoginFailed(req, username, reason) {
  const ip = extractClientIp(req);
  const ts = new Date().toISOString();
  console.log(`[AUTH_FAIL] timestamp=${ts} ip=${ip} user=${username} reason=${reason} LOGIN_FAILED`);
}

function logPostStatus(req, username, postId, fromStatus, toStatus) {
  const ip = extractClientIp(req);
  const ts = new Date().toISOString();
  console.log(`[POST_STATUS] timestamp=${ts} ip=${ip} user=${username} post_id=${postId} from=${fromStatus} to=${toStatus}`);
}

function requireAuth(req, res, next) {
  if (!req.session || !req.session.user) {
    if (req.xhr || req.headers.accept?.includes('json')) {
      return res.status(401).json({ error: 'Yêu cầu đăng nhập để thực hiện' });
    }
    return res.redirect(`/login?returnTo=${encodeURIComponent(req.originalUrl)}`);
  }
  if (!req.session.user.is_active) {
    req.session.destroy();
    return res.status(403).render('errors/403', {
      title: 'Tài khoản đã bị khóa',
      message: 'Tài khoản của bạn đã bị vô hiệu hóa bởi quản trị viên.'
    });
  }
  next();
}

function requireRole(allowedRoles) {
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
  return (req, res, next) => {
    if (!req.session || !req.session.user) {
      return res.redirect(`/login?returnTo=${encodeURIComponent(req.originalUrl)}`);
    }
    const userRole = req.session.user.role;
    if (!roles.includes(userRole)) {
      return res.status(403).render('errors/403', {
        title: 'Truy cập bị từ chối (403 Forbidden)',
        message: 'Bạn không có quyền thực hiện thao tác hoặc truy cập vào khu vực này.'
      });
    }
    next();
  };
}

module.exports = {
  extractClientIp,
  logLoginSuccess,
  logLoginFailed,
  logPostStatus,
  requireAuth,
  requireRole
};