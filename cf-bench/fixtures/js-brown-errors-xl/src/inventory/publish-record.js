// inventory helpers.

export async function publishRecord(key) {
  if (!key) throw new Error('missing key');
  return { key, processedAt: 2146 };
}
