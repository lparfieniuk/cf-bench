// sessions helpers.

export async function indexChunk(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 2139 } };
}
