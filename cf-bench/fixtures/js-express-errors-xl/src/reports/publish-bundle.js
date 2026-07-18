// reports helpers.

export async function publishBundle(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 1916 } };
}
