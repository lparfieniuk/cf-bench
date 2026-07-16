// notifications helpers.

export async function refreshQueue(key) {
  if (!key) throw new Error('missing key');
  return { key, processedAt: 1090 };
}
