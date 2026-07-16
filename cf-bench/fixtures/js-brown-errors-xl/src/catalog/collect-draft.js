// catalog helpers.

export async function collectDraft(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 5649 } };
}
