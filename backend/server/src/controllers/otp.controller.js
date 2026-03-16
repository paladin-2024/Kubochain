const twilio = require('twilio');
const { query } = require('../config/db');

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

const generateOtp = () =>
  Math.floor(100000 + Math.random() * 900000).toString();

exports.sendOtp = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ message: 'Phone number required' });

    const code = generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    // Invalidate any previous unused OTPs for this phone
    await query(
      'UPDATE otp_codes SET used = true WHERE phone = $1 AND used = false',
      [phone]
    );

    // Store new OTP
    await query(
      'INSERT INTO otp_codes (phone, code, expires_at) VALUES ($1, $2, $3)',
      [phone, code, expiresAt]
    );

    if (process.env.NODE_ENV === 'development') {
      // In dev mode: skip SMS, print OTP to server console
      console.log(`\n📱 DEV OTP for ${phone}: ${code}\n`);
      return res.json({ message: 'OTP sent (dev mode — check server console)', devOtp: code });
    }

    // Production: send real SMS via Twilio
    await client.messages.create({
      body: `Your KuboChain verification code is: ${code}. Valid for 5 minutes. Do not share this code.`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phone,
    });

    res.json({ message: 'OTP sent successfully' });
  } catch (err) {
    console.error('Send OTP error:', err.message);
    res.status(500).json({ message: 'Failed to send OTP. Check your phone number.' });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { phone, code } = req.body;
    if (!phone || !code) {
      return res.status(400).json({ message: 'Phone and code required' });
    }

    const { rows } = await query(
      `SELECT id FROM otp_codes
       WHERE phone = $1 AND code = $2 AND used = false AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [phone, code]
    );

    if (!rows[0]) {
      return res.status(400).json({ message: 'Invalid or expired OTP' });
    }

    await query('UPDATE otp_codes SET used = true WHERE id = $1', [rows[0].id]);

    res.json({ verified: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
