const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { query } = require('../config/db');
const { formatUser } = require('../models/formatters');
const { sendPush } = require('../config/firebase-admin');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `profile_${req.user.id}_${Date.now()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only image files are allowed'));
  },
});

exports.uploadMiddleware = upload.single('image');

// Document upload middleware — accepts images or PDFs, up to 3 files
const docStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `doc_${req.user.id}_${Date.now()}_${Math.random().toString(36).slice(2, 6)}${ext}`);
  },
});
const docUpload = multer({
  storage: docStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB per file
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
    if (allowed.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Only images and PDFs are allowed'));
  },
});
exports.uploadDocumentsMiddleware = docUpload.array('documents', 3);

// PUT /api/auth/documents — driver uploads NID, licence, insurance etc.
exports.uploadDocuments = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'No documents uploaded' });
    }
    const urls = req.files.map(f => `/uploads/${f.filename}`);
    await query(
      `UPDATE drivers SET documents = $1, verification_status = 'under_review'
       WHERE user_id = $2`,
      [urls, req.user.id]
    );
    res.json({ success: true, documents: urls });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// PUT /api/auth/profile-image
exports.updateProfileImage = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No image uploaded' });

    const imageUrl = `/uploads/${req.file.filename}`;

    const { rows } = await query(
      'UPDATE users SET profile_image = $1 WHERE id = $2 RETURNING *',
      [imageUrl, req.user.id]
    );

    res.json({ user: formatUser(rows[0]), imageUrl });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// PUT /api/auth/fcm-token
exports.updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ message: 'fcmToken required' });
    await query('UPDATE users SET fcm_token = $1 WHERE id = $2', [fcmToken, req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// In-memory notification log (resets on server restart)
const _notifLog = [];

// GET /api/admin/notifications/history
exports.getNotificationHistory = (req, res) => {
  res.json({ notifications: _notifLog });
};

// POST /api/admin/notifications — send push to all or by role
exports.sendAdminNotification = async (req, res) => {
  try {
    const { title, body, targetRole } = req.body;
    if (!title || !body) return res.status(400).json({ message: 'title and body required' });

    const whereClause = targetRole
      ? "WHERE role = $1 AND fcm_token IS NOT NULL AND fcm_token != ''"
      : "WHERE fcm_token IS NOT NULL AND fcm_token != ''";
    const params = targetRole ? [targetRole] : [];
    const { rows } = await query(`SELECT fcm_token FROM users ${whereClause}`, params);

    const tokens = rows.map((r) => r.fcm_token).filter(Boolean);
    if (tokens.length === 0) {
      _notifLog.unshift({ id: Date.now(), title, body, target: targetRole || 'all', type: 'broadcast', created_at: new Date().toISOString(), sent: 0 });
      return res.json({ message: 'No registered devices to notify', sent: 0 });
    }

    await sendPush({ tokens, title, body });
    _notifLog.unshift({ id: Date.now(), title, body, target: targetRole || 'all', type: 'broadcast', created_at: new Date().toISOString(), sent: tokens.length });
    if (_notifLog.length > 100) _notifLog.pop();
    res.json({ message: 'Notification sent', sent: tokens.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
