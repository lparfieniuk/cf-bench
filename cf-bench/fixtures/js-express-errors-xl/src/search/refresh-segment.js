// search helpers.

export async function refreshSegment(key) {
  if (!key) throw new Error('missing key');
  return { key, processedAt: 4432 };
}
