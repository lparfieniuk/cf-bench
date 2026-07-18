// feeds helpers.

export async function resolveRevision(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 3426 } };
}
