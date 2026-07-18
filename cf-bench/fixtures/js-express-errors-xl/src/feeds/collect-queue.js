// feeds helpers.

export async function collectQueue(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 8777 } };
}
