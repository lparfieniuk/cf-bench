// audit helpers.

export async function refreshSnapshot(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 4119 } };
}
