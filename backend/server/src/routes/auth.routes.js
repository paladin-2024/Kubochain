const router = require('express').Router();
const { register, login, getMe, updateProfile } = require('../controllers/auth.controller');
const { sendOtp, verifyOtp } = require('../controllers/otp.controller');
const { updateProfileImage, uploadMiddleware, updateFcmToken, uploadDocuments, uploadDocumentsMiddleware } = require('../controllers/profile.controller');
const { protect } = require('../middleware/auth.middleware');

router.post('/send-otp', sendOtp);
router.post('/verify-otp', verifyOtp);
router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getMe);
router.put('/profile-image', protect, uploadMiddleware, updateProfileImage);
router.put('/fcm-token', protect, updateFcmToken);
router.put('/profile', protect, updateProfile);
router.put('/documents', protect, uploadDocumentsMiddleware, uploadDocuments);

module.exports = router;
