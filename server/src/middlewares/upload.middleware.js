const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
const uploadDir = path.join(__dirname, '../../public/uploads');
const profilePictureDir = path.join(uploadDir, 'profile-pictures');

// Create directories if they don't exist
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

if (!fs.existsSync(profilePictureDir)) {
  fs.mkdirSync(profilePictureDir, { recursive: true });
}

// Configure storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Determine destination based on file type
    if (file.fieldname === 'profilePicture') {
      cb(null, profilePictureDir);
    } else {
      cb(null, uploadDir);
    }
  },
  filename: function (req, file, cb) {
    // Generate unique filename: timestamp-originalname
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, uniqueSuffix + ext);
  }
});

// File filter function
const fileFilter = (req, file, cb) => {
  
  // Accept images only - check both MIME type and file extension
  const allowedMimeTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/gif',
    'image/bmp',
    'image/webp',
    'image/heic',
    'image/heif',
    'application/octet-stream' // iOS sometimes sends images as octet-stream
  ];
  
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'];
  const fileExt = path.extname(file.originalname).toLowerCase();
  
  // Check if MIME type is allowed OR if file extension is allowed (for iOS compatibility)
  const isMimeTypeAllowed = allowedMimeTypes.includes(file.mimetype.toLowerCase());
  const isExtensionAllowed = allowedExtensions.includes(fileExt);
  
  if (isMimeTypeAllowed || isExtensionAllowed || file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

// Create multer instance with configuration
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max file size
  },
  fileFilter: fileFilter
});

module.exports = upload; 