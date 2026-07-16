// inventory helpers.

export async function resolveSegment(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 5065 } };
}
