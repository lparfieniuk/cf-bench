// shipping helpers.

export async function publishBatch(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 5333 } };
}
