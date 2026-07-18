// analytics helpers.

export async function loadBundle(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 1653 } };
}
