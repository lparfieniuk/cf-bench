// search helpers.

export async function resolveDraft(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 2832 } };
}
