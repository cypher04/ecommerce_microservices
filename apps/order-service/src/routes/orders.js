const express = require('express');
const { query, getClient } = require('../db');
const { authenticate } = require('../middleware/auth');
const { validateProducts } = require('../clients/product-client');
const { processPayment } = require('../clients/payment-client');
const logger = require('../logger');

const router = express.Router();

// Create order (protected)
router.post('/', authenticate, async (req, res) => {
  const client = await getClient();
  try {
    const { items } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Order must contain at least one item' });
    }

    // Validate products exist and have sufficient stock
    let validatedItems;
    try {
      validatedItems = await validateProducts(items);
    } catch (err) {
      return res.status(400).json({ error: err.message });
    }

    const totalAmount = validatedItems.reduce(
      (sum, item) => sum + item.price * item.quantity, 0
    );

    await client.query('BEGIN');

    // Create the order
    const orderResult = await client.query(
      `INSERT INTO orders.orders (user_id, total_amount, status)
       VALUES ($1, $2, 'pending')
       RETURNING *`,
      [req.user.id, totalAmount]
    );
    const order = orderResult.rows[0];

    // Insert order items
    for (const item of validatedItems) {
      await client.query(
        `INSERT INTO orders.order_items (order_id, product_id, product_name, quantity, price)
         VALUES ($1, $2, $3, $4, $5)`,
        [order.id, item.product_id, item.product_name, item.quantity, item.price]
      );
    }

    await client.query('COMMIT');

    // Process payment (outside transaction — order already persisted)
    try {
      const payment = await processPayment(order.id, totalAmount);
      const newStatus = payment.status === 'success' ? 'paid' : 'failed';
      await query(
        'UPDATE orders.orders SET status = $1, payment_id = $2 WHERE id = $3',
        [newStatus, payment.id, order.id]
      );
      order.status = newStatus;
      order.payment_id = payment.id;
    } catch (err) {
      logger.error('Payment processing failed', { orderId: order.id, error: err.message });
      await query('UPDATE orders.orders SET status = $1 WHERE id = $2', ['failed', order.id]);
      order.status = 'failed';
    }

    // Fetch items for response
    const itemsResult = await query(
      'SELECT * FROM orders.order_items WHERE order_id = $1',
      [order.id]
    );

    logger.info('Order created', { orderId: order.id, status: order.status, total: totalAmount });
    res.status(201).json({ order: { ...order, items: itemsResult.rows } });
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Create order error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

// List user's orders (protected)
router.get('/', authenticate, async (req, res) => {
  try {
    const result = await query(
      'SELECT * FROM orders.orders WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.id]
    );
    res.json({ orders: result.rows });
  } catch (err) {
    logger.error('List orders error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get order detail (protected)
router.get('/:id', authenticate, async (req, res) => {
  try {
    const orderResult = await query(
      'SELECT * FROM orders.orders WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const itemsResult = await query(
      'SELECT * FROM orders.order_items WHERE order_id = $1',
      [req.params.id]
    );

    res.json({ order: { ...orderResult.rows[0], items: itemsResult.rows } });
  } catch (err) {
    logger.error('Get order error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
