require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const logger = require('./logger');
const { checkConnection } = require('./db');
const productRoutes = require('./routes/products');

const app = express();
const PORT = parseInt(process.env.PORT, 10) || 3002;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined', {
  stream: { write: (message) => logger.info(message.trim()) }
}));

// Routes
app.use('/api/products', productRoutes);

// Health check
app.get('/health', async (req, res) => {
  try {
    await checkConnection();
    res.json({ status: 'ok', service: 'product-service', timestamp: new Date().toISOString() });
  } catch (err) {
    logger.error('Health check failed', { error: err.message });
    res.status(503).json({ status: 'unhealthy', service: 'product-service', error: 'Database connection failed' });
  }
});

app.get('/livez', (req, res) => res.sendStatus(200));

app.listen(PORT, () => {
  logger.info(`Product service running on port ${PORT}`);
});

module.exports = app;
