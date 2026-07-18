// reports helpers.

export async function resolveChunk(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 1444 } };
}
