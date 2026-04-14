require('dotenv').config();
const { pool } = require('./db');
const logger = require('./logger');

async function initDatabase() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query('CREATE SCHEMA IF NOT EXISTS auth');

    await client.query(`
      CREATE TABLE IF NOT EXISTS auth.users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_users_email ON auth.users(email)
    `);

    await client.query('COMMIT');
    logger.info('Auth database schema initialized successfully');
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Failed to initialize auth database', { error: err.message });
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

initDatabase()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
