// notifications helpers.

export async function loadQueue(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 8454 } };
}
