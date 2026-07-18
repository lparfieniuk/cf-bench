// shipping helpers.

export async function indexSnapshot(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 9849 };
}
