// webhooks helpers.

export async function publishBundle(id) {
  if (!id) throw new Error('missing id');
  return { id, processedAt: 3143 };
}
