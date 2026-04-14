require('dotenv').config();
const express = require('express');
const path = require('path');
const morgan = require('morgan');
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'frontend' },
  transports: [new winston.transports.Console()]
});

const app = express();
const PORT = parseInt(process.env.PORT, 10) || 3000;

app.use(morgan('combined', {
  stream: { write: (message) => logger.info(message.trim()) }
}));

// Serve static files
app.use(express.static(path.join(__dirname, '..', 'public')));

// API config endpoint — tells the frontend where backend services live
app.get('/api/config', (req, res) => {
  res.json({
    authServiceUrl: process.env.AUTH_SERVICE_URL || 'http://localhost:3001',
    productServiceUrl: process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002',
    orderServiceUrl: process.env.ORDER_SERVICE_URL || 'http://localhost:3003'
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'frontend', timestamp: new Date().toISOString() });
});

// SPA fallback — serve index.html for unmatched routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'index.html'));
});

app.listen(PORT, () => {
  logger.info(`Frontend running on port ${PORT}`);
});

module.exports = app;
