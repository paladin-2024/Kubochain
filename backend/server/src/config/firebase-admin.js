const admin = require('firebase-admin');

let initialized = false;

const initFirebase = () => {
  if (initialized) return true;
  if (!process.env.FIREBASE_PROJECT_ID) {
    console.warn('Firebase not configured — push notifications disabled');
    return false;
  }
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    });
    initialized = true;
    console.log('Firebase Admin initialized');
    return true;
  } catch (err) {
    console.error('Firebase init failed:', err.message);
    return false;
  }
};

const sendPush = async ({ token, tokens, title, body, data = {} }) => {
  if (!initFirebase()) return null;

  const payload = {
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
  };

  if (tokens && tokens.length > 0) {
    return admin.messaging().sendEachForMulticast({ ...payload, tokens });
  }
  if (token) {
    return admin.messaging().send({ ...payload, token });
  }
};

module.exports = { sendPush, initFirebase };
