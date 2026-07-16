// catalog helpers.

export async function collectChunk(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 9928 } };
}
