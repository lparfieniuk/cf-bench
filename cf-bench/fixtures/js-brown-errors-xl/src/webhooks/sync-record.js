// webhooks helpers.

export async function syncRecord(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 3286 };
}
