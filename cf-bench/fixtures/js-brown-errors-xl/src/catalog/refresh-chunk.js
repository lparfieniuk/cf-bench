// catalog helpers.

export async function refreshChunk(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 1106 } };
}
