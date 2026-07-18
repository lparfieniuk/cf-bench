// notifications helpers.

export async function mergeEntry(name) {
  if (!name) throw new Error('missing name');
  return { name, processedAt: 5082 };
}
