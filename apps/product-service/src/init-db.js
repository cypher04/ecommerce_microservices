require('dotenv').config();
const { pool } = require('./db');
const logger = require('./logger');

async function initDatabase() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query('CREATE SCHEMA IF NOT EXISTS products');

    await client.query(`
      CREATE TABLE IF NOT EXISTS products.products (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
        stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
        image_url VARCHAR(500),
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_products_name ON products.products(name)
    `);

    await client.query('COMMIT');
    logger.info('Products database schema initialized successfully');
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Failed to initialize products database', { error: err.message });
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

initDatabase()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
