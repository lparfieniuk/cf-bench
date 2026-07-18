// notifications helpers.

export async function publishEntry(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 1006 };
}
