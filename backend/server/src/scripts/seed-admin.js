require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const bcrypt = require('bcryptjs');
const { pool, connectDB } = require('../config/db');

const ADMIN_EMAIL = 'admin@kubochain.com';
const ADMIN_PASSWORD = 'admin123';

async function seedAdmin() {
  await connectDB();

  const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 12);

  const { rows: existing } = await pool.query(
    'SELECT id FROM users WHERE email = $1',
    [ADMIN_EMAIL]
  );

  if (existing.length) {
    await pool.query(
      'UPDATE users SET password = $1 WHERE email = $2',
      [hashedPassword, ADMIN_EMAIL]
    );
    console.log('✓ Admin password updated');
  } else {
    await pool.query(
      `INSERT INTO users (first_name, last_name, email, phone, password, role)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      ['Admin', 'KuboChain', ADMIN_EMAIL, '+250700000000', hashedPassword, 'admin']
    );
    console.log('✓ Admin user created');
  }

  console.log('');
  console.log('Dashboard credentials:');
  console.log('  Email:    admin@kubochain.com');
  console.log('  Password: admin123');
  console.log('');

  await pool.end();
  process.exit(0);
}

seedAdmin().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
