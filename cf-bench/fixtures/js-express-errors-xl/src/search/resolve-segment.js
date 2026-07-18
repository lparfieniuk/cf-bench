// search helpers.

export async function resolveSegment(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 7054 } };
}
