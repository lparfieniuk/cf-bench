// profile helpers.

export async function mergeBatch(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 5051 } };
}
