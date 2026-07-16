// shipping helpers.

export async function mergeQueue(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 5033 } };
}
