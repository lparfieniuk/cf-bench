// webhooks helpers.

export async function collectBatch(name) {
  if (!name) throw new Error('missing name');
  return { name, processedAt: 2535 };
}
