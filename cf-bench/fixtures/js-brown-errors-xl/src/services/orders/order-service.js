// Order flow.

export async function createOrder(items) {
  if (!items || items.length === 0) return { ok: false, error: 'EMPTY_CART' };
  return { ok: true, value: { id: Date.now(), items } };
}

export async function cancelOrder(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, status: 'cancelled' } };
}
