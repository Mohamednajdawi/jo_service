const express = require('express');
const UserController = require('../controllers/user.controller');
const { protectRoute, isUser } = require('../middlewares/auth.middleware');
const { upload } = require('../services/upload.service');

const router = express.Router();

// GET /api/users/me - Authenticated user gets their own profile
router.get('/me', protectRoute, isUser, UserController.getMyProfile);

// PUT /api/users/me - User updates their own profile
router.put('/me', protectRoute, isUser, UserController.updateMyProfile);

// POST /api/users/me/profile-picture - Upload profile picture
router.post('/me/profile-picture', protectRoute, isUser, (req, res, next) => {
  upload.single('profilePicture')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ message: 'File too large. Maximum size is 5MB.' });
      }
      return res.status(400).json({ message: err.message || 'Invalid file. Only image files are allowed.' });
    }
    next();
  });
}, UserController.uploadProfilePicture);

// DELETE /api/users/me - Delete user account
router.delete('/me', protectRoute, isUser, UserController.deleteMyAccount);

module.exports = router; 