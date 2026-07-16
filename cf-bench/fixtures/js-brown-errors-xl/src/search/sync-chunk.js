// search helpers.

export async function syncChunk(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 5010 } };
}
