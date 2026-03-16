require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

async function migrate() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 20000,
  });

  try {
    console.log('Connecting to Neon...');
    await pool.query('SELECT 1');
    console.log('✓ Connected');
  } catch (err) {
    console.error('Connection failed:', err.message);
    process.exit(1);
  }

  const sql = fs.readFileSync(path.join(__dirname, '../models/schema.sql'), 'utf8');
  try {
    await pool.query(sql);
    console.log('✓ Schema migrated successfully');
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  }

  await pool.end();
  process.exit(0);
}

migrate();
