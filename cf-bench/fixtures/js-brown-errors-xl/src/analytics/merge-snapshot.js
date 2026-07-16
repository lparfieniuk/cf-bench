// analytics helpers.

export async function mergeSnapshot(name) {
  if (!name) throw new Error('missing name');
  return { name, processedAt: 9595 };
}
