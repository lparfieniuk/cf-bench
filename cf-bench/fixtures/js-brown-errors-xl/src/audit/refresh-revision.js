// audit helpers.

export async function refreshRevision(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 1188 } };
}
