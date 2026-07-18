// Refund domain service. May throw domain errors (err.code, err.status set).
export async function createRefund(orderId, amount) {
  if (orderId === 'closed-1') {
    const err = new Error('order is closed');
    err.code = 'ORDER_CLOSED';
    err.status = 409;
    throw err;
  }
  return { id: 'r-' + orderId, orderId, amount, state: 'pending' };
}
