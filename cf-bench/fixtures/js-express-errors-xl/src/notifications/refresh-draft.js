// notifications helpers.

export async function refreshDraft(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 1960 } };
}
