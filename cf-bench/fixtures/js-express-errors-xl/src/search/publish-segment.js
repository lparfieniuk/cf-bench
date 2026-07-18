// search helpers.

export async function publishSegment(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 3085 } };
}
