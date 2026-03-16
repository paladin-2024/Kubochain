const router = require('express').Router();
const { getStats, getAllRides, getAllDrivers, getAllUsers, getUserById, getActiveRides, getReports, getTopRiders } = require('../controllers/admin.controller');
const { sendAdminNotification, getNotificationHistory } = require('../controllers/profile.controller');
const { protect, adminOnly } = require('../middleware/auth.middleware');

router.use(protect, adminOnly);

router.get('/stats', getStats);
router.get('/rides', getAllRides);
router.get('/rides/active', getActiveRides);
router.get('/drivers', getAllDrivers);
router.get('/users', getAllUsers);
router.get('/users/:id', getUserById);
router.get('/reports', getReports);
router.get('/top-riders', getTopRiders);
router.get('/notifications/history', getNotificationHistory);
router.post('/notifications', sendAdminNotification);

module.exports = router;
