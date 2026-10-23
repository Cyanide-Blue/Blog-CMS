const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { requireAuth, requireRole } = require('../middleware/auth');

// Require strictly admin role
router.use(requireAuth);
router.use(requireRole('admin'));

// KPI Dashboard
router.get('/dashboard', adminController.getDashboard);

// Approval Queue
router.get('/queue', adminController.getQueue);
router.post('/posts/:id/status', adminController.updatePostStatus);

// Categories CRUD
router.get('/categories', adminController.getCategories);
router.post('/categories', adminController.createCategory);
router.post('/categories/:id/delete', adminController.deleteCategory);

// Tags CRUD
router.get('/tags', adminController.getTags);
router.post('/tags', adminController.createTag);
router.post('/tags/:id/delete', adminController.deleteTag);

// Comments Moderation
router.get('/comments', adminController.getComments);

// Users Management
router.get('/users', adminController.getUsers);
router.post('/users', adminController.createUser);
router.post('/users/:id/role', adminController.updateUserRole);
router.post('/users/:id/toggle-active', adminController.toggleUserActive);

// Media Library
router.get('/media', adminController.getMedia);
router.post('/media/:id/delete', adminController.deleteMedia);

module.exports = router;