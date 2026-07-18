// feeds helpers.

export async function refreshRevision(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 7201 } };
}
