// notifications helpers.

export async function collectSegment(ref) {
  if (!ref) return { ok: false, error: 'MISSING_REF' };
  return { ok: true, value: { ref, processedAt: 5438 } };
}
