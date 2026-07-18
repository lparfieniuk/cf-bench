// webhooks helpers.

export async function collectBundle(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 3200 } };
}
