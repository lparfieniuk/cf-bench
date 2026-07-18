// notifications helpers.

export async function publishRevision(key) {
  if (!key) throw new Error('missing key');
  return { key, processedAt: 5471 };
}
