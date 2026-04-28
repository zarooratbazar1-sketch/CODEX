const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const config = require('./config/env');

const authRoutes = require('./api/v1/routes/auth.routes');
const inventoryRoutes = require('./api/v1/routes/inventory.routes');
const salesRoutes = require('./api/v1/routes/sales.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(rateLimit({ windowMs: config.rateLimitWindowMs, max: config.rateLimitMax }));

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/inventory', inventoryRoutes);
app.use('/api/v1/sales', salesRoutes);

app.use((err, req, res, _next) => {
  res.status(400).json({ message: err.message || 'Request failed' });
});

module.exports = app;
