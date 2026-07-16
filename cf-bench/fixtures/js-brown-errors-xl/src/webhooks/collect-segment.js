// webhooks helpers.

export async function collectSegment(id) {
  if (!id) throw new Error('missing id');
  return { id, processedAt: 5279 };
}
