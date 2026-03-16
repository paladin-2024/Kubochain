const { query } = require('../config/db');
const { formatRide } = require('../models/formatters');
const { sendPush } = require('../config/firebase-admin');

// Full ride with passenger + driver info via JOINs
const RIDE_SQL = `
  SELECT
    r.*,
    up.first_name  AS passenger_first_name,
    up.last_name   AS passenger_last_name,
    up.phone       AS passenger_phone,
    up.rating      AS passenger_rating,
    up.profile_image AS passenger_profile_image,
    d.id           AS driver_id,
    d.user_id      AS driver_user_id,
    d.vehicle_make, d.vehicle_model, d.vehicle_color, d.vehicle_plate, d.vehicle_type,
    ud.first_name  AS driver_first_name,
    ud.last_name   AS driver_last_name,
    ud.phone       AS driver_phone,
    ud.rating      AS driver_rating,
    ud.profile_image AS driver_profile_image
  FROM rides r
  LEFT JOIN users up ON r.passenger_id = up.id
  LEFT JOIN drivers d  ON r.driver_id  = d.id
  LEFT JOIN users ud ON d.user_id = ud.id`;

const getRide = (id) =>
  query(`${RIDE_SQL} WHERE r.id = $1`, [id]).then(({ rows }) => rows[0] || null);

// Passenger creates a ride request
exports.createRide = async (req, res) => {
  try {
    const { pickup, destination, rideType, price, distance } = req.body;

    const { rows } = await query(
      `INSERT INTO rides
         (passenger_id, pickup_address, pickup_lat, pickup_lng,
          destination_address, destination_lat, destination_lng,
          ride_type, price, distance, estimated_minutes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
      [
        req.user.id,
        pickup.address, pickup.lat, pickup.lng,
        destination.address, destination.lat, destination.lng,
        rideType || 'economy',
        price, distance,
        Math.ceil(distance * 4),
      ]
    );

    const ride = await getRide(rows[0].id);
    const formatted = formatRide(ride);

    const io = req.app.get('io');
    io.to('drivers_online').emit('ride:newRequest', { ride: formatted });

    // FCM push to all online drivers so they're alerted even if app is backgrounded
    try {
      const { rows: driverTokens } = await query(
        `SELECT u.fcm_token FROM drivers d
         JOIN users u ON d.user_id = u.id
         WHERE d.is_online = true AND u.fcm_token IS NOT NULL AND u.fcm_token != ''`
      );
      const tokens = driverTokens.map(r => r.fcm_token).filter(Boolean);
      if (tokens.length > 0) {
        const passengerName = `${ride.passenger_first_name || ''} ${ride.passenger_last_name || ''}`.trim() || 'Passenger';
        await sendPush({
          tokens,
          title: '🚀 New Ride Request!',
          body: `${passengerName} needs a ride — ${pickup.address.split(',')[0]}`,
          data: {
            type: 'new_ride_request',
            rideId: String(formatted._id),
            pickupLat: String(pickup.lat),
            pickupLng: String(pickup.lng),
            pickupAddress: pickup.address,
            passengerName,
          },
        });
      }
    } catch (pushErr) {
      console.error('FCM push error (createRide):', pushErr.message);
    }

    res.status(201).json({ ride: formatted });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Driver accepts a ride
exports.acceptRide = async (req, res) => {
  try {
    const { rows: driverRows } = await query(
      'SELECT id FROM drivers WHERE user_id = $1', [req.user.id]
    );
    if (!driverRows[0]) return res.status(404).json({ message: 'Driver profile not found' });
    const driverId = driverRows[0].id;

    const { rows } = await query(
      `UPDATE rides SET driver_id = $1, status = 'accepted', accepted_at = NOW()
       WHERE id = $2 AND status = 'pending' RETURNING id`,
      [driverId, req.params.id]
    );
    if (!rows[0]) return res.status(400).json({ message: 'Ride no longer available' });

    const ride = await getRide(rows[0].id);
    const formatted = formatRide(ride);

    const io = req.app.get('io');
    io.to(`ride_${rows[0].id}`).emit('ride:accepted', { ride: formatted });

    // FCM push to passenger so they're notified even with app backgrounded
    try {
      const { rows: passengerToken } = await query(
        `SELECT u.fcm_token FROM users u
         JOIN rides r ON r.passenger_id = u.id
         WHERE r.id = $1 AND u.fcm_token IS NOT NULL AND u.fcm_token != ''`,
        [rows[0].id]
      );
      if (passengerToken[0]?.fcm_token) {
        const driverName = [
          ride.driver_first_name,
          ride.driver_last_name,
        ].filter(Boolean).join(' ') || 'Your driver';
        await sendPush({
          token: passengerToken[0].fcm_token,
          title: '🏍️ Ride Accepted!',
          body: `${driverName} accepted your ride and is on the way`,
          data: {
            type: 'ride_accepted',
            rideId: String(rows[0].id),
          },
        });
      }
    } catch (pushErr) {
      console.error('FCM push error (acceptRide):', pushErr.message);
    }

    res.json({ ride: formatted });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Driver marks arrived at pickup
exports.driverArrived = async (req, res) => {
  try {
    const { rows } = await query(
      `UPDATE rides SET status = 'arriving', arrived_at = NOW()
       WHERE id = $1 RETURNING id`,
      [req.params.id]
    );
    if (!rows[0]) return res.status(404).json({ message: 'Ride not found' });

    const io = req.app.get('io');
    io.to(`ride_${rows[0].id}`).emit('ride:driverArrived', { rideId: rows[0].id });

    res.json({ success: true, rideId: rows[0].id });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Driver starts trip
exports.startRide = async (req, res) => {
  try {
    const { rows } = await query(
      `UPDATE rides SET status = 'in_progress', started_at = NOW()
       WHERE id = $1 RETURNING id`,
      [req.params.id]
    );
    if (!rows[0]) return res.status(404).json({ message: 'Ride not found' });

    const io = req.app.get('io');
    io.to(`ride_${rows[0].id}`).emit('ride:started', { rideId: rows[0].id });

    res.json({ success: true, rideId: rows[0].id });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Driver completes trip
exports.completeRide = async (req, res) => {
  try {
    const { rows } = await query(
      `UPDATE rides SET status = 'completed', completed_at = NOW()
       WHERE id = $1 RETURNING id, driver_id, passenger_id, price`,
      [req.params.id]
    );
    if (!rows[0]) return res.status(404).json({ message: 'Ride not found' });
    const { id, driver_id, passenger_id, price } = rows[0];

    // Update driver earnings and ride counts
    await Promise.all([
      query(
        `UPDATE drivers
         SET total_earnings = total_earnings + $1,
             today_earnings = today_earnings + $1,
             total_rides    = total_rides + 1
         WHERE id = $2`,
        [price, driver_id]
      ),
      query(
        'UPDATE users SET total_rides = total_rides + 1 WHERE id = $1',
        [passenger_id]
      ),
    ]);

    const ride = await getRide(id);
    const formatted = formatRide(ride);

    const io = req.app.get('io');
    io.to(`ride_${id}`).emit('ride:completed', { ride: formatted });

    res.json({ ride: formatted });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Cancel ride
exports.cancelRide = async (req, res) => {
  try {
    const cancelledBy = req.user.role === 'rider' ? 'driver' : 'passenger';
    const reason = req.body.reason || 'No reason provided';

    const { rows } = await query(
      `UPDATE rides
       SET status = 'cancelled', cancel_reason = $1, cancelled_by = $2
       WHERE id = $3 AND status NOT IN ('completed','cancelled')
       RETURNING id`,
      [reason, cancelledBy, req.params.id]
    );
    if (!rows[0]) return res.status(400).json({ message: 'Ride cannot be cancelled' });

    const io = req.app.get('io');
    io.to(`ride_${rows[0].id}`).emit('ride:cancelled', { rideId: rows[0].id, reason });

    res.json({ success: true, rideId: rows[0].id });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Rate ride
exports.rateRide = async (req, res) => {
  try {
    const { rating, comment, tags } = req.body;

    const { rows } = await query(
      `UPDATE rides SET rating = $1, rating_comment = $2, rating_tags = $3
       WHERE id = $4 AND rating IS NULL RETURNING id, driver_id`,
      [rating, comment || null, tags || [], req.params.id]
    );
    if (!rows[0]) return res.status(404).json({ message: 'Ride not found or already rated' });

    // Recalculate driver avg rating + increment rating_count
    if (rows[0].driver_id) {
      await query(
        `UPDATE drivers SET
           rating       = (SELECT ROUND(AVG(rating)::numeric, 2) FROM rides
                           WHERE driver_id = $1 AND status = 'completed' AND rating IS NOT NULL),
           rating_count = (SELECT COUNT(*) FROM rides
                           WHERE driver_id = $1 AND status = 'completed' AND rating IS NOT NULL)
         WHERE id = $1`,
        [rows[0].driver_id]
      );
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get my rides (passenger or driver)
exports.getMyRides = async (req, res) => {
  try {
    let rows;
    if (req.user.role === 'rider') {
      const { rows: dr } = await query(
        'SELECT id FROM drivers WHERE user_id = $1', [req.user.id]
      );
      if (!dr[0]) return res.json({ rides: [] });
      ({ rows } = await query(
        `${RIDE_SQL} WHERE r.driver_id = $1 ORDER BY r.created_at DESC`,
        [dr[0].id]
      ));
    } else {
      ({ rows } = await query(
        `${RIDE_SQL} WHERE r.passenger_id = $1 ORDER BY r.created_at DESC`,
        [req.user.id]
      ));
    }
    res.json({ rides: rows.map(formatRide) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get single ride
exports.getRide = async (req, res) => {
  try {
    const ride = await getRide(req.params.id);
    if (!ride) return res.status(404).json({ message: 'Ride not found' });
    res.json({ ride: formatRide(ride) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
