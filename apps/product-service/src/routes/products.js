const express = require('express');
const { query } = require('../db');
const { authenticate } = require('../middleware/auth');
const logger = require('../logger');

const router = express.Router();

// List all products (public)
router.get('/', async (req, res) => {
  try {
    const result = await query('SELECT * FROM products.products ORDER BY created_at DESC');
    res.json({ products: result.rows });
  } catch (err) {
    logger.error('List products error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get single product (public)
router.get('/:id', async (req, res) => {
  try {
    const result = await query('SELECT * FROM products.products WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    res.json({ product: result.rows[0] });
  } catch (err) {
    logger.error('Get product error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create product (protected)
router.post('/', authenticate, async (req, res) => {
  try {
    const { name, description, price, stock, image_url } = req.body;

    if (!name || price === undefined) {
      return res.status(400).json({ error: 'Name and price are required' });
    }

    const result = await query(
      `INSERT INTO products.products (name, description, price, stock, image_url)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [name, description || null, price, stock || 0, image_url || null]
    );

    logger.info('Product created', { productId: result.rows[0].id, name });
    res.status(201).json({ product: result.rows[0] });
  } catch (err) {
    logger.error('Create product error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update product (protected)
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { name, description, price, stock, image_url } = req.body;

    const existing = await query('SELECT id FROM products.products WHERE id = $1', [req.params.id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const result = await query(
      `UPDATE products.products
       SET name = COALESCE($1, name),
           description = COALESCE($2, description),
           price = COALESCE($3, price),
           stock = COALESCE($4, stock),
           image_url = COALESCE($5, image_url),
           updated_at = NOW()
       WHERE id = $6
       RETURNING *`,
      [name, description, price, stock, image_url, req.params.id]
    );

    logger.info('Product updated', { productId: req.params.id });
    res.json({ product: result.rows[0] });
  } catch (err) {
    logger.error('Update product error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete product (protected)
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const result = await query('DELETE FROM products.products WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    logger.info('Product deleted', { productId: req.params.id });
    res.json({ message: 'Product deleted' });
  } catch (err) {
    logger.error('Delete product error', { error: err.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
