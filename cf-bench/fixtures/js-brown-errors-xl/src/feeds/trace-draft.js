// feeds helpers.

export async function traceDraft(ref) {
  if (!ref) throw new Error('missing ref');
  return { ref, processedAt: 5720 };
}
