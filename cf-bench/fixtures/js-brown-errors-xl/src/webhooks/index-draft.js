// webhooks helpers.

export async function indexDraft(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 2188 } };
}
