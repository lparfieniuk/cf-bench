// sessions helpers.

export async function traceQueue(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 4295 } };
}
