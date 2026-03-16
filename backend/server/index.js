require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const { connectDB } = require('./src/config/db');
const { initFirebase } = require('./src/config/firebase-admin');

// Route imports
const authRoutes   = require('./src/routes/auth.routes');
const rideRoutes   = require('./src/routes/ride.routes');
const driverRoutes = require('./src/routes/driver.routes');
const adminRoutes  = require('./src/routes/admin.routes');
const chatRoutes   = require('./src/routes/chat.routes');

// Socket handler
const socketHandler = require('./src/socket/socket.handler');

const app    = express();
const server = http.createServer(app);

// Socket.io setup
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

// Make io accessible in controllers via req.app.get('io')
app.set('io', io);

// Connect to Neon PostgreSQL
connectDB();

// Initialize Firebase Admin (optional — only if FIREBASE_PROJECT_ID is set)
initFirebase();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes
app.use('/api/auth',    authRoutes);
app.use('/api/rides',   rideRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/admin',   adminRoutes);
app.use('/api/chat',    chatRoutes);

// Serve uploaded profile images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check
app.get('/health', (req, res) => res.json({ status: 'OK', timestamp: new Date() }));

// 404 handler
app.use((req, res) => res.status(404).json({ message: 'Route not found' }));

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Internal server error' });
});

// Socket.io event handlers
socketHandler(io);

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`KuboChain Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
