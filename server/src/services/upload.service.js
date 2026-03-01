const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Create uploads directory if it doesn't exist
const uploadDir = path.join(__dirname, '../../public/uploads/profile-pictures');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure storage
const storage = multer.diskStorage({
  destination: function(req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function(req, file, cb) {
    // Generate a unique filename using timestamp and original extension
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, 'profile-' + uniqueSuffix + ext);
  }
});

// File filter: accept images including HEIC and octet-stream (iOS compatibility)
const allowedMimeTypes = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/gif',
  'image/bmp',
  'image/webp',
  'image/heic',
  'image/heif',
  'application/octet-stream'
];
const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'];

const fileFilter = (req, file, cb) => {
  const fileExt = path.extname(file.originalname).toLowerCase();
  const isMimeOk = allowedMimeTypes.includes((file.mimetype || '').toLowerCase());
  const isExtOk = allowedExtensions.includes(fileExt);
  if (isMimeOk || isExtOk || (file.mimetype && file.mimetype.startsWith('image/'))) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

// Create multer middleware with file filtering
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB max file size
  },
  fileFilter
});

module.exports = { upload }; 