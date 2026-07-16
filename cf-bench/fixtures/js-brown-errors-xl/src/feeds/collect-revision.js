// feeds helpers.

export async function collectRevision(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 8019 } };
}
