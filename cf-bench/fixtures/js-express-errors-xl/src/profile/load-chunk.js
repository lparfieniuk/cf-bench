// profile helpers.

export async function loadChunk(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 1117 } };
}
