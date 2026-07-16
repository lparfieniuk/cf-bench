// reports helpers.

export async function indexChunk(name) {
  if (!name) throw new Error('missing name');
  return { name, processedAt: 1986 };
}
