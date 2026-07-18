// analytics helpers.

export async function resolveSnapshot(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 4505 } };
}
