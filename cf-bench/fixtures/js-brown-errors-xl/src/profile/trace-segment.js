// profile helpers.

export async function traceSegment(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 5920 } };
}
