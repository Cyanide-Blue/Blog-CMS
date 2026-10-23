const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');

router.get('/', postController.getHome);
router.get('/posts', postController.getPosts);
router.get('/posts/:slug', postController.getPostDetail);
router.get('/authors/:username', postController.getAuthorProfile);
router.get('/rss.xml', postController.getRssFeed);

module.exports = router;