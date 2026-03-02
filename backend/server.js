const express = require('express');
const cors = require('cors');
const passport = require('passport');
const { connectDB } = require('./config/db');
const { configurePassport } = require('./config/passport');

const authRoutes = require('./routes/auth');
const categoriesRoutes = require('./routes/categories');
const servicesRoutes = require('./routes/services');
const bookingsRoutes = require('./routes/bookings');
const messagesRoutes = require('./routes/messages');
const providersRoutes = require('./routes/providers');

const app = express();
const BASE_PORT = parseInt(process.env.PORT, 10) || 3000;
const MAX_PORT_ATTEMPTS = 20; // try 3000–3019 (or PORT to PORT+19)

configurePassport(passport);

app.use(cors());
app.use(express.json());
app.use(passport.initialize());

const routes = [
  { path: '/api/auth', name: 'Auth (login, register, me)' },
  { path: '/api/categories', name: 'Categories' },
  { path: '/api/services', name: 'Services' },
  { path: '/api/bookings', name: 'Bookings' },
  { path: '/api/messages', name: 'Messages' },
  { path: '/api/providers', name: 'Providers (me/status, me profile)' },
];

app.use('/api/auth', authRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/services', servicesRoutes);
app.use('/api/bookings', bookingsRoutes);
app.use('/api/messages', messagesRoutes);
app.use('/api/providers', providersRoutes);

// Health: returns real DB status and server info
app.get('/api/health', (req, res) => {
  const mongoose = require('mongoose');
  const dbState = mongoose.connection.readyState;
  const dbStatus = dbState === 1 ? 'connected' : dbState === 2 ? 'connecting' : dbState === 3 ? 'disconnecting' : 'disconnected';
  res.json({
    status: 'ok',
    db: dbStatus,
    port: app.get('port') ?? process.env.PORT ?? BASE_PORT,
    uptimeSeconds: Math.floor(process.uptime()),
    routes: routes.map((r) => r.path),
  });
});

function logStatus(port) {
  const mongoose = require('mongoose');
  const dbHost = mongoose.connection?.host || '—';
  console.log('\n  Serbisyo API — status');
  console.log('  ─────────────────────────────');
  console.log(`  Server:  http://localhost:${port}`);
  console.log(`  DB:      connected (${dbHost})`);
  console.log('  Routes:');
  routes.forEach((r) => console.log(`    ${r.path}`));
  console.log('  ─────────────────────────────');
  console.log(`  Health:  http://localhost:${port}/api/health`);
  console.log('  ─────────────────────────────\n');
}

function tryListen(port, attempt = 0) {
  if (attempt >= MAX_PORT_ATTEMPTS) {
    console.error(`No free port in range ${BASE_PORT}–${BASE_PORT + MAX_PORT_ATTEMPTS - 1}. Set PORT in .env or free a port.`);
    process.exit(1);
  }
  const server = app.listen(port, '0.0.0.0', () => {
    app.set('port', port);
    console.log(`Serbisyo API running at http://localhost:${port}`);
    console.log(`Also reachable on your network (use your PC IP and port ${port} for mobile)`);
    if (port !== BASE_PORT) {
      console.log(`Tip: Port ${BASE_PORT} was in use. Update mobile .env API_BASE_URL to use port ${port} if needed.`);
    }
    logStatus(port);
  });
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      server.close(() => {
        console.warn(`Port ${port} in use, trying ${port + 1}...`);
        tryListen(port + 1, attempt + 1);
      });
    } else {
      console.error('Server error:', err);
      process.exit(1);
    }
  });
}

connectDB().then(() => {
  tryListen(BASE_PORT);
}).catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
