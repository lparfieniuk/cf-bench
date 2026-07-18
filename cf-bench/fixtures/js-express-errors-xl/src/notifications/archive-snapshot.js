// notifications helpers.

export async function archiveSnapshot(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 2489 } };
}
