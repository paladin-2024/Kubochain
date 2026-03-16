const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { formatUser } = require('../models/formatters');

const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    token = req.headers.authorization.split(' ')[1];
  }
  if (!token) return res.status(401).json({ message: 'Not authenticated' });

  // Verify JWT — role is embedded in the payload so no DB query is needed
  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    return res.status(401).json({ message: 'Invalid token' });
  }

  if (!decoded.id) return res.status(401).json({ message: 'Invalid token payload' });

  // Fast path: role is in the JWT (all tokens issued after this fix)
  if (decoded.role) {
    req.user = { id: decoded.id, role: decoded.role };
    return next();
  }

  // Legacy path: old tokens without role — fetch once from DB
  try {
    const { rows } = await query('SELECT id, role FROM users WHERE id = $1', [decoded.id]);
    if (!rows[0]) return res.status(401).json({ message: 'User not found' });
    req.user = { id: rows[0].id, role: rows[0].role };
    next();
  } catch (err) {
    console.error('Auth DB error:', err.message);
    return res.status(503).json({ message: 'Database unavailable, please retry' });
  }
};

const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
};

const riderOnly = (req, res, next) => {
  if (req.user.role !== 'rider' && req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Rider access required' });
  }
  next();
};

module.exports = { protect, adminOnly, riderOnly };
