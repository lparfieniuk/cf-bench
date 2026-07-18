// feeds helpers.

export async function refreshBatch(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 4241 } };
}
