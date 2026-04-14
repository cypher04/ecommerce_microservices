require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const logger = require('./logger');
const { checkConnection } = require('./db');
const authRoutes = require('./routes/auth');

const app = express();
const PORT = parseInt(process.env.PORT, 10) || 3001;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined', {
  stream: { write: (message) => logger.info(message.trim()) }
}));

// Routes
app.use('/api/auth', authRoutes);

// Health check
app.get('/health', async (req, res) => {
  try {
    await checkConnection();
    res.json({ status: 'ok', service: 'auth-service', timestamp: new Date().toISOString() });
  } catch (err) {
    logger.error('Health check failed', { error: err.message });
    res.status(503).json({ status: 'unhealthy', service: 'auth-service', error: 'Database connection failed' });
  }
});

app.listen(PORT, () => {
  logger.info(`Auth service running on port ${PORT}`);
});

module.exports = app;
