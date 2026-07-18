// reports helpers.

export async function resolveDraft(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 8251 } };
}
