const logger = require('../logger');

const PAYMENT_SERVICE_URL = process.env.PAYMENT_SERVICE_URL || 'http://localhost:3004';

async function processPayment(orderId, amount) {
  const response = await fetch(`${PAYMENT_SERVICE_URL}/api/payments/process`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      order_id: orderId,
      amount,
      card_last_four: '4242'
    })
  });

  if (!response.ok) {
    throw new Error(`Payment service returned ${response.status}`);
  }

  const data = await response.json();
  logger.info('Payment processed', { orderId, paymentId: data.payment.id, status: data.payment.status });
  return data.payment;
}

module.exports = { processPayment };
