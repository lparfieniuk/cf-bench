// analytics helpers.

export async function collectBatch(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 9317 } };
}
