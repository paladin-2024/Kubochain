const { query } = require('../config/db');
const { formatRide, formatDriver, formatUser } = require('../models/formatters');

exports.getStats = async (req, res) => {
  try {
    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

    const [
      { rows: [total] },
      { rows: [todayRow] },
      { rows: [active] },
      { rows: [completed] },
      { rows: [cancelled] },
      { rows: [drivers] },
      { rows: [online] },
      { rows: [passengers] },
      { rows: [revenue] },
      { rows: daily },
    ] = await Promise.all([
      query('SELECT COUNT(*) AS count FROM rides'),
      query("SELECT COUNT(*) AS count FROM rides WHERE created_at >= $1::date", [today]),
      query("SELECT COUNT(*) AS count FROM rides WHERE status IN ('pending','accepted','arriving','in_progress')"),
      query("SELECT COUNT(*) AS count FROM rides WHERE status = 'completed'"),
      query("SELECT COUNT(*) AS count FROM rides WHERE status = 'cancelled'"),
      query('SELECT COUNT(*) AS count FROM drivers'),
      query('SELECT COUNT(*) AS count FROM drivers WHERE is_online = true'),
      query("SELECT COUNT(*) AS count FROM users WHERE role = 'passenger'"),
      query("SELECT COALESCE(SUM(price), 0) AS total FROM rides WHERE status = 'completed'"),
      query(
        `SELECT
           TO_CHAR(created_at, 'YYYY-MM-DD') AS date,
           SUM(price) AS revenue,
           COUNT(*) AS count
         FROM rides
         WHERE status = 'completed'
           AND created_at >= NOW() - INTERVAL '7 days'
         GROUP BY date
         ORDER BY date ASC`
      ),
    ]);

    res.json({
      totalRides:      parseInt(total.count),
      todayRides:      parseInt(todayRow.count),
      activeRides:     parseInt(active.count),
      completedRides:  parseInt(completed.count),
      cancelledRides:  parseInt(cancelled.count),
      totalDrivers:    parseInt(drivers.count),
      onlineDrivers:   parseInt(online.count),
      totalPassengers: parseInt(passengers.count),
      totalRevenue:    parseFloat(revenue.total),
      dailyRevenue: daily.map((r) => ({
        _id:     r.date,
        revenue: parseFloat(r.revenue),
        count:   parseInt(r.count),
      })),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getAllRides = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const whereClause = status ? 'WHERE r.status = $3' : '';
    const params = status
      ? [parseInt(limit), offset, status]
      : [parseInt(limit), offset];

    const { rows } = await query(
      `SELECT
         r.*,
         up.first_name AS passenger_first_name, up.last_name AS passenger_last_name,
         up.phone AS passenger_phone, up.rating AS passenger_rating,
         up.profile_image AS passenger_profile_image,
         d.id AS driver_id, d.user_id AS driver_user_id,
         d.vehicle_make, d.vehicle_model, d.vehicle_color, d.vehicle_plate, d.vehicle_type,
         ud.first_name AS driver_first_name, ud.last_name AS driver_last_name,
         ud.phone AS driver_phone, ud.rating AS driver_rating,
         ud.profile_image AS driver_profile_image
       FROM rides r
       LEFT JOIN users up ON r.passenger_id = up.id
       LEFT JOIN drivers d ON r.driver_id = d.id
       LEFT JOIN users ud ON d.user_id = ud.id
       ${whereClause}
       ORDER BY r.created_at DESC
       LIMIT $1 OFFSET $2`,
      params
    );

    const { rows: [{ count }] } = await query(
      status ? 'SELECT COUNT(*) AS count FROM rides WHERE status = $1' : 'SELECT COUNT(*) AS count FROM rides',
      status ? [status] : []
    );

    res.json({
      rides: rows.map(formatRide),
      total: parseInt(count),
      pages: Math.ceil(parseInt(count) / parseInt(limit)),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getAllDrivers = async (req, res) => {
  try {
    const { rows } = await query(
      `SELECT d.*,
         u.first_name AS user_first_name, u.last_name AS user_last_name,
         u.email AS user_email, u.phone AS user_phone,
         u.rating AS user_rating, u.profile_image AS user_profile_image
       FROM drivers d
       JOIN users u ON d.user_id = u.id
       ORDER BY d.created_at DESC`
    );
    res.json({ drivers: rows.map(formatDriver) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getAllUsers = async (req, res) => {
  try {
    const { role, search } = req.query;

    let whereClause = '';
    const params = [];

    const conditions = [];
    if (role) {
      params.push(role);
      conditions.push(`role = $${params.length}`);
    }
    if (search) {
      params.push(`%${search}%`);
      const idx = params.length;
      conditions.push(
        `(first_name ILIKE $${idx} OR last_name ILIKE $${idx} OR email ILIKE $${idx} OR phone ILIKE $${idx})`
      );
    }
    if (conditions.length) whereClause = 'WHERE ' + conditions.join(' AND ');

    const { rows } = await query(
      `SELECT * FROM users ${whereClause} ORDER BY created_at DESC`,
      params
    );
    res.json({ users: rows.map(formatUser), total: rows.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const { rows } = await query('SELECT * FROM users WHERE id = $1', [req.params.id]);
    if (!rows[0]) return res.status(404).json({ message: 'User not found' });

    const user = formatUser(rows[0]);

    // Get ride history
    const rideField = rows[0].role === 'rider'
      ? 'r.driver_id IN (SELECT id FROM drivers WHERE user_id = $1)'
      : 'r.passenger_id = $1';

    const { rows: rides } = await query(
      `SELECT r.id, r.status, r.price, r.distance, r.created_at,
              r.pickup_address, r.destination_address
       FROM rides r
       WHERE ${rideField}
       ORDER BY r.created_at DESC LIMIT 10`,
      [req.params.id]
    );

    res.json({ user, recentRides: rides });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getReports = async (req, res) => {
  try {
    const { from, to } = req.query;
    const fromDate = from || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    const toDate   = to   || new Date().toISOString().slice(0, 10);

    const [
      { rows: daily },
      { rows: byType },
      { rows: topDrivers },
      { rows: hourly },
      { rows: [summary] },
      { rows: userGrowth },
    ] = await Promise.all([
      query(
        `SELECT TO_CHAR(created_at,'YYYY-MM-DD') AS date, SUM(price) AS revenue, COUNT(*) AS count
         FROM rides WHERE status='completed'
           AND created_at >= $1::date AND created_at < ($2::date + interval '1 day')
         GROUP BY date ORDER BY date ASC`,
        [fromDate, toDate]
      ),
      query(
        `SELECT ride_type AS type, SUM(price) AS revenue, COUNT(*) AS count
         FROM rides WHERE status='completed'
           AND created_at >= $1::date AND created_at < ($2::date + interval '1 day')
         GROUP BY ride_type`,
        [fromDate, toDate]
      ),
      query(
        `SELECT d.id, u.first_name, u.last_name, d.total_rides AS trips,
                d.total_earnings AS earnings, d.rating
         FROM drivers d JOIN users u ON d.user_id = u.id
         ORDER BY d.total_earnings DESC LIMIT 10`
      ),
      query(
        `SELECT EXTRACT(HOUR FROM created_at)::int AS hour, COUNT(*) AS count
         FROM rides WHERE status='completed'
           AND created_at >= $1::date AND created_at < ($2::date + interval '1 day')
         GROUP BY hour ORDER BY hour ASC`,
        [fromDate, toDate]
      ),
      query(
        `SELECT COALESCE(SUM(price),0) AS revenue, COUNT(*) AS count, AVG(price) AS avg_fare
         FROM rides WHERE status='completed'
           AND created_at >= $1::date AND created_at < ($2::date + interval '1 day')`,
        [fromDate, toDate]
      ),
      query(
        `SELECT TO_CHAR(created_at,'YYYY-MM-DD') AS date, COUNT(*) AS count, role
         FROM users
         WHERE created_at >= NOW() - INTERVAL '30 days'
         GROUP BY date, role ORDER BY date ASC`
      ),
    ]);

    res.json({
      daily: daily.map((r) => ({
        date: r.date,
        revenue: parseFloat(r.revenue),
        count: parseInt(r.count),
      })),
      byType: byType.map((r) => ({
        type: r.type || 'economy',
        revenue: parseFloat(r.revenue),
        count: parseInt(r.count),
      })),
      topDrivers: topDrivers.map((r, i) => ({
        rank: i + 1,
        id: r.id,
        name: `${r.first_name} ${r.last_name}`,
        trips: parseInt(r.trips || 0),
        earnings: parseFloat(r.earnings || 0),
        rating: parseFloat(r.rating || 5),
      })),
      hourly: Array.from({ length: 24 }, (_, h) => {
        const found = hourly.find((r) => parseInt(r.hour) === h);
        return { hour: `${String(h).padStart(2,'0')}h`, count: found ? parseInt(found.count) : 0 };
      }),
      summary: {
        revenue: parseFloat(summary?.revenue || 0),
        trips: parseInt(summary?.count || 0),
        avgFare: parseFloat(summary?.avg_fare || 0),
      },
      userGrowth,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getTopRiders = async (req, res) => {
  try {
    const { limit = 20, sort = 'rating' } = req.query;
    const orderBy = sort === 'trips'    ? 'd.total_rides DESC'
                  : sort === 'earnings' ? 'd.total_earnings DESC'
                  :                       'd.rating DESC NULLS LAST, d.rating_count DESC';

    const { rows } = await query(
      `SELECT
         d.id,
         d.rating,
         d.rating_count,
         d.total_rides,
         d.total_earnings,
         d.vehicle_make,
         d.vehicle_model,
         d.vehicle_plate,
         d.vehicle_type,
         d.is_online,
         u.first_name,
         u.last_name,
         u.profile_image,
         u.phone,
         (SELECT COUNT(*) FROM rides r2
          WHERE r2.driver_id = d.id AND r2.status = 'completed'
            AND r2.rating >= 5) AS five_star_count,
         (SELECT ARRAY_AGG(tag ORDER BY cnt DESC) FROM (
           SELECT UNNEST(rating_tags) AS tag, COUNT(*) AS cnt
           FROM rides WHERE driver_id = d.id AND rating_tags IS NOT NULL AND array_length(rating_tags,1) > 0
           GROUP BY tag LIMIT 3
         ) t) AS top_tags
       FROM drivers d
       JOIN users u ON d.user_id = u.id
       WHERE d.rating_count > 0
       ORDER BY ${orderBy}
       LIMIT $1`,
      [parseInt(limit)]
    );

    res.json({
      riders: rows.map((r, i) => ({
        rank: i + 1,
        id: r.id,
        name: `${r.first_name} ${r.last_name}`.trim(),
        profileImage: r.profile_image,
        phone: r.phone,
        rating: parseFloat(r.rating || 0),
        ratingCount: parseInt(r.rating_count || 0),
        totalRides: parseInt(r.total_rides || 0),
        totalEarnings: parseFloat(r.total_earnings || 0),
        fiveStarCount: parseInt(r.five_star_count || 0),
        topTags: r.top_tags || [],
        vehicle: `${r.vehicle_make || ''} ${r.vehicle_model || ''}`.trim(),
        vehiclePlate: r.vehicle_plate || '',
        vehicleType: r.vehicle_type || 'motorcycle',
        isOnline: r.is_online || false,
      })),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getActiveRides = async (req, res) => {
  try {
    const { rows } = await query(
      `SELECT
         r.*,
         up.first_name AS passenger_first_name, up.last_name AS passenger_last_name,
         up.phone AS passenger_phone, up.rating AS passenger_rating,
         up.profile_image AS passenger_profile_image,
         d.id AS driver_id, d.user_id AS driver_user_id,
         d.vehicle_make, d.vehicle_model, d.vehicle_color, d.vehicle_plate, d.vehicle_type,
         ud.first_name AS driver_first_name, ud.last_name AS driver_last_name,
         ud.phone AS driver_phone, ud.rating AS driver_rating,
         ud.profile_image AS driver_profile_image
       FROM rides r
       LEFT JOIN users up ON r.passenger_id = up.id
       LEFT JOIN drivers d ON r.driver_id = d.id
       LEFT JOIN users ud ON d.user_id = ud.id
       WHERE r.status IN ('pending','accepted','arriving','in_progress')
       ORDER BY r.created_at DESC`
    );
    res.json({ rides: rows.map(formatRide) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
