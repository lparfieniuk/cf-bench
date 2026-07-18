// search helpers.

export async function mergeBundle(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 5499 } };
}
