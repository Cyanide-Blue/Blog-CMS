const express = require('express');
const router = express.Router();
const commentController = require('../controllers/commentController');
const { requireAuth } = require('../middleware/auth');

router.post('/comments', requireAuth, commentController.createComment);
router.post('/comments/:id/delete', requireAuth, commentController.deleteComment);
router.post('/comments/:id/toggle', requireAuth, commentController.toggleCommentStatus);

module.exports = router;