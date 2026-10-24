const express = require('express');
const router = express.Router();
const path = require('path');
const postController = require('../controllers/postController');

router.get('/', postController.getHome);
router.get('/posts', postController.getPosts);
router.get('/posts/:slug', postController.getPostDetail);
router.get('/authors/:username', postController.getAuthorProfile);
router.get('/rss.xml', postController.getRssFeed);
router.get('/rss.xsl', (req, res) => {
  res.setHeader('Content-Type', 'text/xsl; charset=utf-8');
  res.sendFile(path.join(__dirname, '../../public/rss.xsl'));
});

module.exports = router;