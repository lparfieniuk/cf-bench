// feeds helpers.

export async function loadSnapshot(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 6413 } };
}
