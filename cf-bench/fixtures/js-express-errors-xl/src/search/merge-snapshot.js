// search helpers.

export async function mergeSnapshot(key) {
  if (!key) throw new Error('missing key');
  return { key, processedAt: 5011 };
}
