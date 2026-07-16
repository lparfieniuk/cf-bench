// feeds helpers.

export async function syncRevision(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 6573 } };
}
