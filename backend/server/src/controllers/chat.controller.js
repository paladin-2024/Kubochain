const { query } = require('../config/db');
const { sendPush } = require('../config/firebase-admin');

// GET /api/chat/conversations — all ride-chats for the current user
exports.getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const { rows } = await query(
      `SELECT DISTINCT ON (m.ride_id)
         m.ride_id,
         m.content          AS last_message,
         m.created_at       AS last_message_at,
         m.sender_id,
         -- other user info
         CASE
           WHEN m.sender_id = $1 THEN other_u.id
           ELSE m.sender_id
         END AS other_user_id,
         other_u.first_name AS other_first_name,
         other_u.last_name  AS other_last_name,
         other_u.profile_image AS other_profile_image,
         other_u.role       AS other_role,
         -- unread count
         (SELECT COUNT(*) FROM messages um
          WHERE um.ride_id = m.ride_id
            AND um.receiver_id = $1 AND um.is_read = false) AS unread_count
       FROM messages m
       JOIN users other_u ON other_u.id = CASE
         WHEN m.sender_id = $1 THEN m.receiver_id
         ELSE m.sender_id
       END
       WHERE m.sender_id = $1 OR m.receiver_id = $1
       ORDER BY m.ride_id, m.created_at DESC`,
      [userId]
    );

    res.json({ conversations: rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// GET /api/chat/:rideId — all messages for a ride
exports.getMessages = async (req, res) => {
  try {
    const { rideId } = req.params;
    const userId = req.user.id;

    const { rows } = await query(
      `SELECT m.*,
         u.first_name AS sender_first_name,
         u.last_name  AS sender_last_name,
         u.profile_image AS sender_profile_image
       FROM messages m
       JOIN users u ON m.sender_id = u.id
       WHERE m.ride_id = $1
         AND (m.sender_id = $2 OR m.receiver_id = $2)
       ORDER BY m.created_at ASC`,
      [rideId, userId]
    );

    // Mark all received messages as read
    await query(
      `UPDATE messages SET is_read = true
       WHERE ride_id = $1 AND receiver_id = $2 AND is_read = false`,
      [rideId, userId]
    );

    res.json({ messages: rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// POST /api/chat/:rideId — send a message
exports.sendMessage = async (req, res) => {
  try {
    const { rideId } = req.params;
    const { receiverId, content } = req.body;
    const senderId = req.user.id;

    if (!content?.trim()) return res.status(400).json({ message: 'Message content required' });
    if (!receiverId)       return res.status(400).json({ message: 'Receiver ID required' });

    const { rows } = await query(
      `INSERT INTO messages (ride_id, sender_id, receiver_id, content)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [rideId, senderId, receiverId, content.trim()]
    );

    const message = rows[0];

    // Also fetch sender info to return full message
    const { rows: senderRows } = await query(
      'SELECT first_name, last_name, profile_image FROM users WHERE id = $1',
      [senderId]
    );
    const full = {
      ...message,
      sender_first_name:   senderRows[0]?.first_name,
      sender_last_name:    senderRows[0]?.last_name,
      sender_profile_image: senderRows[0]?.profile_image,
    };

    // Broadcast to the ride room so the recipient gets real-time delivery
    const io = req.app.get('io');
    if (io) {
      io.to(`ride_${rideId}`).emit('chat:message', { message: full });
    }

    // FCM push to receiver (works even if app is closed/backgrounded)
    try {
      const { rows: receiverRow } = await query(
        `SELECT fcm_token, first_name FROM users WHERE id = $1 AND fcm_token IS NOT NULL AND fcm_token != ''`,
        [receiverId]
      );
      if (receiverRow[0]?.fcm_token) {
        const senderName = `${senderRows[0]?.first_name || ''} ${senderRows[0]?.last_name || ''}`.trim() || 'Someone';
        await sendPush({
          token: receiverRow[0].fcm_token,
          title: `💬 ${senderName}`,
          body: content.trim().length > 80 ? content.trim().slice(0, 80) + '…' : content.trim(),
          data: { type: 'chat_message', rideId: String(rideId), senderId: String(senderId) },
        });
      }
    } catch (e) { console.error('FCM chat push:', e.message); }

    res.status(201).json({ message: full });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
