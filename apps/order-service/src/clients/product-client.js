const logger = require('../logger');

const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002';

async function getProduct(productId) {
  const response = await fetch(`${PRODUCT_SERVICE_URL}/api/products/${productId}`);
  if (!response.ok) {
    if (response.status === 404) {
      return null;
    }
    throw new Error(`Product service returned ${response.status}`);
  }
  const data = await response.json();
  return data.product;
}

async function validateProducts(items) {
  const results = [];

  for (const item of items) {
    const product = await getProduct(item.product_id);
    if (!product) {
      throw new Error(`Product ${item.product_id} not found`);
    }
    if (product.stock < item.quantity) {
      throw new Error(`Insufficient stock for ${product.name}: requested ${item.quantity}, available ${product.stock}`);
    }
    results.push({
      product_id: product.id,
      product_name: product.name,
      quantity: item.quantity,
      price: parseFloat(product.price)
    });
  }

  return results;
}

module.exports = { getProduct, validateProducts };
