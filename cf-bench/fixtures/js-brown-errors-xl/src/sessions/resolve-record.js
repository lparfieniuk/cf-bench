// sessions helpers.

export async function resolveRecord(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 2122 } };
}
