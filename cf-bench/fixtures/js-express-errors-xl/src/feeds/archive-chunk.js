// feeds helpers.

export async function archiveChunk(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 4750 };
}
