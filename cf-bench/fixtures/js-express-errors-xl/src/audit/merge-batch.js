// audit helpers.

export async function mergeBatch(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 2983 } };
}
