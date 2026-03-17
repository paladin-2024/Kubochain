const { query } = require('../config/db');
const { formatDriver, formatRide } = require('../models/formatters');

const DRIVER_SQL = `
  SELECT
    d.*,
    u.first_name AS user_first_name,
    u.last_name  AS user_last_name,
    u.phone      AS user_phone,
    u.rating     AS user_rating,
    u.profile_image AS user_profile_image
  FROM drivers d
  JOIN users u ON d.user_id = u.id`;

// Get nearby available drivers (Haversine in SQL)
exports.getNearbyDrivers = async (req, res) => {
  try {
    const { lat, lng, maxDistance = 5000 } = req.query;

    const { rows } = await query(
      `${DRIVER_SQL}
       WHERE d.is_online = true AND d.lat IS NOT NULL AND d.lng IS NOT NULL
         AND (6371000 * acos(LEAST(1.0,
               cos(radians($1::float)) * cos(radians(d.lat::float)) *
               cos(radians(d.lng::float) - radians($2::float)) +
               sin(radians($1::float)) * sin(radians(d.lat::float))
             ))) <= $3
       ORDER BY (6371000 * acos(LEAST(1.0,
               cos(radians($1::float)) * cos(radians(d.lat::float)) *
               cos(radians(d.lng::float) - radians($2::float)) +
               sin(radians($1::float)) * sin(radians(d.lat::float))
             )))
       LIMIT 20`,
      [parseFloat(lat), parseFloat(lng), parseInt(maxDistance)]
    );

    res.json({ drivers: rows.map(formatDriver) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Update driver GPS location
exports.updateLocation = async (req, res) => {
  try {
    const { lat, lng } = req.body;

    const { rows } = await query(
      `UPDATE drivers SET lat = $1, lng = $2
       WHERE user_id = $3 RETURNING id`,
      [lat, lng, req.user.id]
    );
    if (!rows[0]) return res.status(404).json({ message: 'Driver not found' });

    // Broadcast to active ride if any
    const { rows: activeRides } = await query(
      `SELECT id FROM rides
       WHERE driver_id = $1 AND status IN ('accepted','arriving','in_progress')
       LIMIT 1`,
      [rows[0].id]
    );
    if (activeRides[0]) {
      const io = req.app.get('io');
      io.to(`ride_${activeRides[0].id}`).emit('ride:driverLocation', {
        lat, lng, rideId: activeRides[0].id,
      });
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Toggle driver online/offline
exports.toggleAvailability = async (req, res) => {
  try {
    const { isOnline } = req.body;
    const { rows } = await query(
      `${DRIVER_SQL}
       WHERE d.user_id = $1`,
      [req.user.id]
    );
    if (!rows[0]) return res.status(404).json({ message: 'Driver not found' });

    await query(
      'UPDATE drivers SET is_online = $1 WHERE user_id = $2',
      [isOnline, req.user.id]
    );

    // If going online, check for any pending ride requests and notify this driver
    if (isOnline) {
      try {
        const pool = require('../config/db').pool;
        const { rows: pendingRides } = await pool.query(
          `SELECT r.id, r.pickup_address,
                  u.first_name AS passenger_first_name, u.last_name AS passenger_last_name
           FROM rides r
           JOIN users u ON r.passenger_id = u.id
           WHERE r.status = 'pending'
           ORDER BY r.created_at DESC
           LIMIT 3`
        );
        if (pendingRides.length > 0) {
          const { rows: driverUserRow } = await pool.query(
            `SELECT u.fcm_token FROM users u WHERE u.id = $1 AND u.fcm_token IS NOT NULL AND u.fcm_token != ''`,
            [req.user.id]
          );
          if (driverUserRow[0]?.fcm_token) {
            const { sendPush } = require('../config/firebase-admin');
            const count = pendingRides.length;
            const first = pendingRides[0];
            const passengerName = `${first.passenger_first_name || ''} ${first.passenger_last_name || ''}`.trim() || 'Passenger';
            await sendPush({
              token: driverUserRow[0].fcm_token,
              title: `🚀 ${count} Ride Request${count > 1 ? 's' : ''} Waiting!`,
              body: `${passengerName} — ${first.pickup_address?.split(',')[0] || 'New ride'}`,
              data: {
                type: 'new_ride_request',
                rideId: String(first.id),
                pickupAddress: first.pickup_address || '',
                passengerName,
              },
            });
          }
        }
      } catch (e) { console.error('FCM pending rides on online:', e.message); }
    }

    res.json({ driver: formatDriver({ ...rows[0], is_online: isOnline }) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Public top-rated drivers for leaderboard (no admin auth required)
exports.getTopRated = async (req, res) => {
  try {
    const { rows } = await query(
      `SELECT
         d.id, d.rating, d.rating_count, d.total_rides, d.total_earnings,
         d.vehicle_make, d.vehicle_model, d.vehicle_plate, d.vehicle_type, d.is_online,
         u.first_name, u.last_name, u.profile_image,
         (SELECT COUNT(*) FROM rides r WHERE r.driver_id = d.id AND r.status='completed' AND r.rating=5) AS five_star_count,
         (SELECT ARRAY_AGG(tag ORDER BY cnt DESC) FROM (
           SELECT UNNEST(rating_tags) AS tag, COUNT(*) AS cnt
           FROM rides WHERE driver_id = d.id AND rating_tags IS NOT NULL AND array_length(rating_tags,1) > 0
           GROUP BY tag LIMIT 3
         ) t) AS top_tags
       FROM drivers d
       JOIN users u ON d.user_id = u.id
       WHERE d.rating_count > 0
       ORDER BY d.rating DESC NULLS LAST, d.rating_count DESC
       LIMIT 20`
    );

    res.json({
      riders: rows.map((r, i) => ({
        rank: i + 1,
        id: r.id,
        name: `${r.first_name} ${r.last_name}`.trim(),
        profileImage: r.profile_image,
        rating: parseFloat(r.rating || 0),
        ratingCount: parseInt(r.rating_count || 0),
        totalRides: parseInt(r.total_rides || 0),
        totalEarnings: parseFloat(r.total_earnings || 0),
        fiveStarCount: parseInt(r.five_star_count || 0),
        topTags: r.top_tags || [],
        vehicle: `${r.vehicle_make || ''} ${r.vehicle_model || ''}`.trim(),
        vehiclePlate: r.vehicle_plate || '',
        isOnline: r.is_online || false,
      })),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get driver earnings + recent rides
exports.getEarnings = async (req, res) => {
  try {
    const { rows: dr } = await query(
      'SELECT * FROM drivers WHERE user_id = $1', [req.user.id]
    );
    if (!dr[0]) return res.status(404).json({ message: 'Driver not found' });
    const driver = dr[0];

    // Reset today_earnings if it's a new day
    const today = new Date().toISOString().slice(0, 10);
    if (driver.last_earnings_reset && driver.last_earnings_reset.toISOString().slice(0, 10) !== today) {
      await query(
        'UPDATE drivers SET today_earnings = 0, last_earnings_reset = CURRENT_DATE WHERE id = $1',
        [driver.id]
      );
      driver.today_earnings = 0;
    }

    const { rows: rideRows } = await query(
      `SELECT
         r.*,
         up.first_name AS passenger_first_name,
         up.last_name  AS passenger_last_name,
         up.phone      AS passenger_phone,
         up.rating     AS passenger_rating,
         up.profile_image AS passenger_profile_image,
         d.id          AS driver_id,
         d.user_id     AS driver_user_id,
         d.vehicle_make, d.vehicle_model, d.vehicle_color, d.vehicle_plate, d.vehicle_type,
         NULL::text    AS driver_first_name,
         NULL::text    AS driver_last_name,
         NULL::text    AS driver_phone,
         NULL::numeric AS driver_rating,
         NULL::text    AS driver_profile_image
       FROM rides r
       LEFT JOIN users up ON r.passenger_id = up.id
       LEFT JOIN drivers d  ON r.driver_id  = d.id
       WHERE r.driver_id = $1 AND r.status = 'completed'
       ORDER BY r.completed_at DESC
       LIMIT 20`,
      [driver.id]
    );

    res.json({
      todayEarnings: parseFloat(driver.today_earnings),
      totalEarnings: parseFloat(driver.total_earnings),
      totalRides: driver.total_rides,
      recentRides: rideRows.map(formatRide),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateVehicle = async (req, res) => {
  try {
    const { vehicleMake, vehicleModel, vehiclePlate, vehicleColor, vehicleType } = req.body;
    const pool = require('../config/db').pool;
    await pool.query(
      `UPDATE drivers SET
        vehicle_make = COALESCE($1, vehicle_make),
        vehicle_model = COALESCE($2, vehicle_model),
        vehicle_plate = COALESCE($3, vehicle_plate),
        vehicle_color = COALESCE($4, vehicle_color),
        vehicle_type = COALESCE($5, vehicle_type)
       WHERE user_id = $6`,
      [vehicleMake, vehicleModel, vehiclePlate, vehicleColor, vehicleType, req.user.id]
    );
    res.json({ message: 'Vehicle updated' });
  } catch (err) {
    console.error('updateVehicle error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};
