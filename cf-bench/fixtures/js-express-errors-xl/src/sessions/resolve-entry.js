// sessions helpers.

export async function resolveEntry(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 3705 } };
}
