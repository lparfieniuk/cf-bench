// webhooks helpers.

export async function refreshQueue(name) {
  if (!name) throw new Error('missing name');
  return { name, processedAt: 3287 };
}
