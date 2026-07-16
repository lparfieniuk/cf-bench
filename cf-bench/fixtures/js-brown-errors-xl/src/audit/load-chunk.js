// audit helpers.

export async function loadChunk(id) {
  if (!id) throw new Error('missing id');
  return { id, processedAt: 9565 };
}
