// feeds helpers.

export async function resolveSnapshot(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 3900 } };
}
