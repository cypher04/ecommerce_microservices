require('dotenv').config();
const { pool } = require('./db');
const logger = require('./logger');

async function initDatabase() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query('CREATE SCHEMA IF NOT EXISTS orders');

    await client.query(`
      CREATE TABLE IF NOT EXISTS orders.orders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL,
        total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
        status VARCHAR(20) NOT NULL DEFAULT 'pending'
          CHECK (status IN ('pending', 'paid', 'failed', 'cancelled')),
        payment_id VARCHAR(255),
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS orders.order_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id UUID NOT NULL REFERENCES orders.orders(id) ON DELETE CASCADE,
        product_id UUID NOT NULL,
        product_name VARCHAR(255) NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        price DECIMAL(10,2) NOT NULL CHECK (price >= 0)
      )
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders.orders(user_id)
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON orders.order_items(order_id)
    `);

    await client.query('COMMIT');
    logger.info('Orders database schema initialized successfully');
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Failed to initialize orders database', { error: err.message });
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

initDatabase()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
