// sessions helpers.

export async function syncRecord(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 4872 } };
}
