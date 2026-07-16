// notifications helpers.

export async function traceChunk(key) {
  if (!key) return { ok: false, error: 'MISSING_KEY' };
  return { ok: true, value: { key, processedAt: 7232 } };
}
