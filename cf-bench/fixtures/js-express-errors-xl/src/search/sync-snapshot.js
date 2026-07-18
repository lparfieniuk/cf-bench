// search helpers.

export async function syncSnapshot(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 3939 };
}
