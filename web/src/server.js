const path = require('path');
const express = require('express');
const session = require('express-session');
const dotenv = require('dotenv');

dotenv.config();

const csrfMiddleware = require('./middleware/csrf');
const healthRoutes = require('./routes/healthRoutes');
const authRoutes = require('./routes/authRoutes');
const postRoutes = require('./routes/postRoutes');
const commentRoutes = require('./routes/commentRoutes');
const authorRoutes = require('./routes/authorRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Security: Disable X-Powered-By header
app.disable('x-powered-by');

// Trust proxy for reverse proxy (Nginx / Docker)
app.set('trust proxy', 1);

// View engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, '../views'));

// Static assets
app.use(express.static(path.join(__dirname, '../public'), {
  setHeaders: (res, filePath) => {
    if (filePath.endsWith('.xsl')) {
      res.setHeader('Content-Type', 'text/xsl; charset=utf-8');
    }
  }
}));

// Body parsers with 2MB limits
app.use(express.urlencoded({ extended: true, limit: '2mb' }));
app.use(express.json({ limit: '2mb' }));

// Session configuration
app.use(
  session({
    secret: process.env.SESSION_SECRET || 'super-secret-key-at-least-20-chars-long',
    resave: false,
    saveUninitialized: false,
    name: 'blogcms_session',
    cookie: {
      httpOnly: true,
      secure: 'auto',
      sameSite: 'strict',
      maxAge: 24 * 60 * 60 * 1000 // 24 hours
    }
  })
);

// Global view variables (Set before CSRF & routes so available everywhere)
app.use((req, res, next) => {
  res.locals.currentUser = req.session?.user || null;
  res.locals.currentPath = req.path || '/';
  next();
});

// Health check before CSRF
app.use(healthRoutes);

// CSRF Protection
app.use(csrfMiddleware);

// App Routes
app.use(authRoutes);
app.use(commentRoutes);
app.use('/author', authorRoutes);
app.use('/admin', adminRoutes);
app.use(postRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).render('errors/404', {
    title: '404 - Trang không tồn tại',
    message: 'Đường dẫn bạn yêu cầu không tồn tại trên hệ thống.'
  });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled application error:', err);
  res.status(500).render('errors/500', {
    title: '500 - Lỗi máy chủ',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Có lỗi kỹ thuật xảy ra trên hệ thống.'
  });
});

const { startTelemetryFeed } = require('./utils/telemetryGenerator');

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Blog/CMS application running on http://0.0.0.0:${PORT}`);
  startTelemetryFeed();
});