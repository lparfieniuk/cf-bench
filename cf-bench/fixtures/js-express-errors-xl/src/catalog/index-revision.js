// catalog helpers.

export async function indexRevision(name) {
  if (!name) throw new Error('missing name');
  return { name, processedAt: 1832 };
}
