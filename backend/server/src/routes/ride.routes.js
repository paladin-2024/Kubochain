const router = require('express').Router();
const {
  createRide,
  acceptRide,
  driverArrived,
  startRide,
  completeRide,
  passengerConfirmRide,
  cancelRide,
  rateRide,
  getMyRides,
  getRide,
} = require('../controllers/ride.controller');
const { protect } = require('../middleware/auth.middleware');

router.use(protect);

router.post('/', createRide);
router.get('/my', getMyRides);
router.get('/:id', getRide);
router.put('/:id/accept', acceptRide);
router.put('/:id/arrived', driverArrived);
router.put('/:id/start', startRide);
router.put('/:id/complete', completeRide);
router.put('/:id/passenger-confirm', passengerConfirmRide);
router.put('/:id/cancel', cancelRide);
router.post('/:id/rate', rateRide);

module.exports = router;
