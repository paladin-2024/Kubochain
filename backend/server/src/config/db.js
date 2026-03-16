const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }, // Required for Neon
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000, // Fail fast so retries work; Neon cold-start is ~5s
});

pool.on('error', (err) => {
  console.error('Unexpected database error:', err.message);
});

const query = (text, params) => pool.query(text, params);

const runMigrations = async () => {
  // Safe, idempotent migrations — add missing columns without recreating tables
  const migrations = [
    `ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT`,
    `ALTER TABLE drivers ADD COLUMN IF NOT EXISTS rating_count INTEGER NOT NULL DEFAULT 0`,
    `ALTER TABLE rides ADD COLUMN IF NOT EXISTS rating_tags TEXT[]`,
    `ALTER TABLE drivers ADD COLUMN IF NOT EXISTS documents TEXT[] DEFAULT '{}'`,
    `ALTER TABLE drivers ADD COLUMN IF NOT EXISTS verification_status TEXT NOT NULL DEFAULT 'pending'`,
  ];
  for (const sql of migrations) {
    try {
      await pool.query(sql);
    } catch (err) {
      console.warn('Migration warning:', err.message);
    }
  }
};

const connectDB = async () => {
  try {
    const res = await pool.query('SELECT NOW()');
    console.log(`Neon PostgreSQL Connected: ${res.rows[0].now}`);
    await runMigrations();
  } catch (err) {
    console.error('Database connection error:', err.message || err.code || JSON.stringify(err));
    // Retry once after 5s (Neon cold start)
    console.log('Retrying in 5s...');
    await new Promise(r => setTimeout(r, 5000));
    try {
      const res = await pool.query('SELECT NOW()');
      console.log(`Neon PostgreSQL Connected (retry): ${res.rows[0].now}`);
      await runMigrations();
    } catch (err2) {
      console.error('Database connection failed after retry:', err2.message || err2.code);
      process.exit(1);
    }
  }
};

module.exports = { pool, query, connectDB };
