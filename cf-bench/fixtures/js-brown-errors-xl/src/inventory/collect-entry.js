// inventory helpers.

export async function collectEntry(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 1893 };
}
