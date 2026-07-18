// reports helpers.

export async function traceChunk(id) {
  if (!id) throw new Error('missing id');
  return { id, processedAt: 4492 };
}
