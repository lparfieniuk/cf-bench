// audit helpers.

export async function collectRecord(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 8811 };
}
