// webhooks helpers.

export async function archiveRecord(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 2729 } };
}
