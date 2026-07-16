// audit helpers.

export async function publishSegment(id) {
  if (!id) throw new Error('missing id');
  return { id, processedAt: 6325 };
}
