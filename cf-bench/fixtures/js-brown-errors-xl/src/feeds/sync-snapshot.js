// feeds helpers.

export async function syncSnapshot(key) {
  if (!key) throw new Error('missing key');
  return { key, processedAt: 2330 };
}
