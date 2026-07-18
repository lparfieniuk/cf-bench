// shipping helpers.

export async function publishSegment(name) {
  if (!name) throw new Error('missing name');
  return { name, processedAt: 1887 };
}
