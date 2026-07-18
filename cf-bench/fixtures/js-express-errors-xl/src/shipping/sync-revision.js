// shipping helpers.

export async function syncRevision(key) {
  if (!key) throw new Error('missing key');
  return { key, processedAt: 4450 };
}
