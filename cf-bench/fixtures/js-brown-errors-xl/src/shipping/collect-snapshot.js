// shipping helpers.

export async function collectSnapshot(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 3330 } };
}
