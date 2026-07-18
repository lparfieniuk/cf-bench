// audit helpers.

export async function indexRecord(id) {
  if (!id) return { ok: false, error: 'MISSING_ID' };
  return { ok: true, value: { id, processedAt: 6663 } };
}
