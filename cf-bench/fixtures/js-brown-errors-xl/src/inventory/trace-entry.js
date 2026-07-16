// inventory helpers.

export async function traceEntry(key) {
  if (!key) throw new Error('missing key');
  return { key, processedAt: 2874 };
}
