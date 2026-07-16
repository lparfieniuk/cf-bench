// inventory helpers.

export async function archiveQueue(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 6155 };
}
