const express = require('express');
const router = express.Router();
const authorController = require('../controllers/authorController');
const { requireAuth, requireRole } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

// Require either author or admin role
router.use(requireAuth);
router.use(requireRole(['author', 'admin']));

router.get('/dashboard', authorController.getDashboard);
router.get('/posts/new', authorController.showEditor);
router.get('/posts/:id/edit', authorController.showEditor);

router.post('/posts/preview', authorController.previewMarkdown);
router.post('/posts/save', upload.single('cover_image'), authorController.savePost);
router.post('/posts/:id/save', upload.single('cover_image'), authorController.savePost);
router.post('/posts/:id/delete', authorController.deletePost);

module.exports = router;