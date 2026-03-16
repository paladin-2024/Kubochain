const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { formatUser } = require('../models/formatters');

const signToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });

exports.register = async (req, res) => {
  try {
    const { firstName, lastName, email, phone, password, role, vehicle, otpCode } = req.body;

    // Verify OTP before creating account
    if (!otpCode) return res.status(400).json({ message: 'OTP code is required' });
    const { rows: otpRows } = await query(
      `SELECT id FROM otp_codes
       WHERE phone = $1 AND code = $2 AND used = false AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [phone, otpCode]
    );
    if (!otpRows[0]) return res.status(400).json({ message: 'Invalid or expired OTP' });
    await query('UPDATE otp_codes SET used = true WHERE id = $1', [otpRows[0].id]);

    const { rows: existing } = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.length) return res.status(409).json({ message: 'Email already in use' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const userRole = role || 'passenger';

    const { rows } = await query(
      `INSERT INTO users (first_name, last_name, email, phone, password, role)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [firstName, lastName, email, phone, hashedPassword, userRole]
    );
    const user = rows[0];

    if (userRole === 'rider') {
      const v = vehicle || {};
      const plate = v.plateNumber || `TMP-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
      await query(
        `INSERT INTO drivers (user_id, vehicle_make, vehicle_model, vehicle_color, vehicle_plate, vehicle_type)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [user.id, v.make || 'Unknown', v.model || 'Unknown', v.color || 'Black', plate, v.type || 'motorcycle']
      );
    }

    const token = signToken(user.id, userRole);
    res.status(201).json({ token, user: formatUser(user) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const { rows } = await query('SELECT * FROM users WHERE email = $1', [email]);
    const user = rows[0];
    if (!user) return res.status(401).json({ message: 'Invalid email or password' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Invalid email or password' });

    const token = signToken(user.id, user.role);
    res.json({ token, user: formatUser(user) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMe = async (req, res) => {
  try {
    const { rows } = await query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    if (!rows[0]) return res.status(404).json({ message: 'User not found' });
    res.json({ user: formatUser(rows[0]) });
  } catch (err) {
    res.status(503).json({ message: 'Database unavailable, please retry' });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { firstName, lastName, email, phone } = req.body;
    const { rows } = await query(
      `UPDATE users SET
         first_name = COALESCE($1, first_name),
         last_name  = COALESCE($2, last_name),
         email      = COALESCE($3, email),
         phone      = COALESCE($4, phone)
       WHERE id = $5 RETURNING *`,
      [firstName || null, lastName || null, email || null, phone || null, req.user.id]
    );
    res.json({ user: formatUser(rows[0]) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
