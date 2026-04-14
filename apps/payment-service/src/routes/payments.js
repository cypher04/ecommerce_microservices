const express = require('express');
const crypto = require('crypto');
const logger = require('../logger');

const router = express.Router();

// In-memory payment store (mock)
const payments = new Map();

// Process payment
router.post('/process', (req, res) => {
  try {
    const { order_id, amount, card_last_four } = req.body;

    if (!order_id || amount === undefined) {
      return res.status(400).json({ error: 'order_id and amount are required' });
    }

    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({ error: 'Amount must be a positive number' });
    }

    // Mock logic: amounts over 1000 fail
    const status = parsedAmount > 1000 ? 'failed' : 'success';
    const paymentId = crypto.randomUUID();

    const payment = {
      id: paymentId,
      order_id,
      amount: parsedAmount,
      card_last_four: card_last_four || '0000',
      status,
      message: status === 'success'
        ? 'Payment processed successfully'
        : 'Payment declined: amount exceeds limit',
      created_at: new Date().toISOString()
    };

    payments.set(paymentId, payment);

    logger.info('Payment processed', { paymentId, orderId: order_id, amount: parsedAmount, status });
    res.status(status === 'success' ? 200 : 402).json({ payment });
  } catch (err) {
    logger.error('Process payment error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get payment status
router.get('/:id', (req, res) => {
  const payment = payments.get(req.params.id);
  if (!payment) {
    return res.status(404).json({ error: 'Payment not found' });
  }
  res.json({ payment });
});

module.exports = router;
