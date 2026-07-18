// catalog helpers.

export async function resolveSegment(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 9689 } };
}
