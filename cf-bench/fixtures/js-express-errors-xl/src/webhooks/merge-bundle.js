// webhooks helpers.

export async function mergeBundle(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 2654 } };
}
