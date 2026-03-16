const router = require('express').Router();
const {
  updateVehicle,
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
router.put('/vehicle', protect, riderOnly, updateVehicle);
router.get('/earnings', protect, riderOnly, getEarnings);

module.exports = router;
