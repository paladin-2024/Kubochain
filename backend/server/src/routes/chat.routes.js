const router = require('express').Router();
const { getConversations, getMessages, sendMessage } = require('../controllers/chat.controller');
const { protect } = require('../middleware/auth.middleware');

router.use(protect);

router.get('/conversations', getConversations);
router.get('/:rideId', getMessages);
router.post('/:rideId', sendMessage);

module.exports = router;
