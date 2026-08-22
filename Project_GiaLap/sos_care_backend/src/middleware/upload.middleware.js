const path = require('path');
const fs = require('fs');
const multer = require('multer');

/**
 * Multipart upload handling for avatar photos.
 *
 * Chạy chủ yếu trên điện thoại nên chấp nhận MỌI định dạng ảnh (jpeg, png,
 * webp, gif, bmp, heic/heif, svg, tiff, avif, ico...). Nếu client không gửi
 * MIME `image/*` (một số Android picker gửi `application/octet-stream`), vẫn
 * chấp nhận miễn là phần mở rộng file là của ảnh. Giới hạn kích thước 5MB.
 *
 * - Memory storage (ảnh ≤ 5MB), validate trước khi ghi đĩa.
 * - Exports uploads root + avatar folder để service/app persist và serve tĩnh.
 */
const UPLOADS_DIR = path.join(__dirname, '..', '..', 'public', 'uploads');
const AVATAR_DIR = path.join(UPLOADS_DIR, 'avatars');

// Map MIME -> extension chuẩn để lưu file đúng định dạng.
const MIME_EXT = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
  'image/bmp': '.bmp',
  'image/heic': '.heic',
  'image/heif': '.heif',
  'image/svg+xml': '.svg',
  'image/tiff': '.tiff',
  'image/avif': '.avif',
  'image/x-icon': '.ico',
};

const IMAGE_EXTENSIONS = new Set([
  '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp',
  '.heic', '.heif', '.svg', '.tif', '.tiff', '.avif', '.ico',
]);

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

const ensureUploadDirs = () => {
  fs.mkdirSync(AVATAR_DIR, { recursive: true });
};

const normalizeMime = (mime) => (mime || '').split(';')[0].trim().toLowerCase();

// Chấp nhận nếu MIME là image/* hoặc (octet-stream + mở rộng file là ảnh).
const isImageRequest = (file) => {
  const mime = normalizeMime(file.mimetype);
  if (mime.startsWith('image/')) return true;
  if (mime === 'application/octet-stream') {
    const ext = path.extname(file.originalname || '').toLowerCase();
    return IMAGE_EXTENSIONS.has(ext);
  }
  return false;
};

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE, files: 1 },
  fileFilter: (req, file, cb) => {
    if (isImageRequest(file)) {
      cb(null, true);
    } else {
      cb(new multer.MulterError('UNSUPPORTED_FILE_TYPE', file.fieldname));
    }
  },
});

module.exports = { upload, UPLOADS_DIR, AVATAR_DIR, MIME_EXT, IMAGE_EXTENSIONS, normalizeMime, ensureUploadDirs };