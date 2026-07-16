// audit helpers.

export async function syncDraft(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 4185 } };
}
