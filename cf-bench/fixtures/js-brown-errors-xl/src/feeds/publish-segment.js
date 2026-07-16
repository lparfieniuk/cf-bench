// feeds helpers.

export async function publishSegment(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 6514 };
}
