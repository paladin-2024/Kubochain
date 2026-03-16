const router = require('express').Router();
const {
  getNearbyDrivers,
  updateLocation,
  toggleAvailability,
  getEarnings,
  getTopRated,
} = require('../controllers/driver.controller');
const { protect, riderOnly } = require('../middleware/auth.middleware');

router.get('/top-rated', protect, getTopRated);
router.get('/nearby', protect, getNearbyDrivers);
router.put('/location', protect, riderOnly, updateLocation);
router.put('/availability', protect, riderOnly, toggleAvailability);
router.get('/earnings', protect, riderOnly, getEarnings);

module.exports = router;
