const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { formatUser } = require('../models/formatters');
const { sendPush } = require('../config/firebase-admin');

module.exports = (io) => {
  // Auth middleware for socket connections
  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.headers.authorization?.split(' ')[1] ||
        socket.handshake.auth?.token;
      if (!token) return next(new Error('No token'));

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const { rows } = await query('SELECT * FROM users WHERE id = $1', [decoded.id]);
      if (!rows[0]) return next(new Error('User not found'));
      socket.user = formatUser(rows[0]);
      next();
    } catch {
      next(new Error('Authentication failed'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.user.email} (${socket.user.role})`);

    // Driver goes online — join or leave drivers room
    socket.on('driver:setOnline', async ({ isOnline }) => {
      if (socket.user.role !== 'rider') return;
      if (isOnline) {
        socket.join('drivers_online');
        console.log(`Driver ${socket.user.email} is ONLINE`);
      } else {
        socket.leave('drivers_online');
        console.log(`Driver ${socket.user.email} is OFFLINE`);
      }
      try {
        await query(
          'UPDATE drivers SET is_online = $1 WHERE user_id = $2',
          [isOnline, socket.user._id]
        );
      } catch {}
    });

    // Driver sends live GPS update
    socket.on('driver:updateLocation', async ({ lat, lng }) => {
      if (socket.user.role !== 'rider') return;
      try {
        const { rows } = await query(
          'UPDATE drivers SET lat = $1, lng = $2 WHERE user_id = $3 RETURNING id',
          [lat, lng, socket.user._id]
        );
        if (!rows[0]) return;

        // Find active ride and broadcast to its room
        const { rows: activeRides } = await query(
          `SELECT id FROM rides
           WHERE driver_id = $1 AND status IN ('accepted','arriving','in_progress')
           LIMIT 1`,
          [rows[0].id]
        );
        if (activeRides[0]) {
          io.to(`ride_${activeRides[0].id}`).emit('ride:driverLocation', {
            lat, lng, rideId: activeRides[0].id,
          });
        }
      } catch {}
    });

    // Join a ride room (passenger and driver)
    socket.on('ride:join', ({ rideId }) => {
      socket.join(`ride_${rideId}`);
      console.log(`${socket.user.email} joined ride room: ${rideId}`);
    });

    // Leave a ride room
    socket.on('ride:leave', ({ rideId }) => {
      socket.leave(`ride_${rideId}`);
    });

    // Driver arrived at pickup (socket shortcut — mirrors the REST endpoint)
    socket.on('ride:arrived', async ({ rideId }) => {
      io.to(`ride_${rideId}`).emit('ride:driverArrived', { rideId });
      try {
        await query(
          "UPDATE rides SET status = 'arriving', arrived_at = NOW() WHERE id = $1",
          [rideId]
        );
      } catch {}
    });

    // ── Chat ────────────────────────────────────────
    // Real-time message delivery within a ride room
    socket.on('chat:send', async ({ rideId, receiverId, content }) => {
      try {
        const senderId = socket.user._id;
        const { rows } = await query(
          `INSERT INTO messages (ride_id, sender_id, receiver_id, content)
           VALUES ($1, $2, $3, $4) RETURNING *`,
          [rideId, senderId, receiverId, content?.trim()]
        );
        const message = {
          ...rows[0],
          sender_first_name:    socket.user.firstName,
          sender_last_name:     socket.user.lastName,
          sender_profile_image: socket.user.profileImage,
        };
        // Deliver to all in ride room (sender sees it too)
        io.to(`ride_${rideId}`).emit('chat:message', { message });

        // FCM push so message arrives even when receiver has app backgrounded
        try {
          const { rows: tokenRows } = await query(
            "SELECT fcm_token, first_name FROM users WHERE id = $1 AND fcm_token IS NOT NULL AND fcm_token != ''",
            [receiverId]
          );
          if (tokenRows[0]?.fcm_token) {
            const senderName = [socket.user.firstName, socket.user.lastName]
              .filter(Boolean).join(' ') || 'Someone';
            await sendPush({
              token: tokenRows[0].fcm_token,
              title: `💬 ${senderName}`,
              body: content?.trim()?.slice(0, 120) || 'Sent you a message',
              data: {
                type: 'chat_message',
                rideId: String(rideId),
                senderId: String(senderId),
              },
            });
          }
        } catch {}
      } catch {}
    });

    socket.on('chat:read', async ({ rideId }) => {
      try {
        await query(
          'UPDATE messages SET is_read = true WHERE ride_id = $1 AND receiver_id = $2',
          [rideId, socket.user._id]
        );
        io.to(`ride_${rideId}`).emit('chat:read', { rideId, userId: socket.user._id });
      } catch {}
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.user?.email}`);
      socket.leave('drivers_online');
    });
  });
};
