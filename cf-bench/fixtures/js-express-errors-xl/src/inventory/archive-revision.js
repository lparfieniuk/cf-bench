// inventory helpers.

export async function archiveRevision(name) {
  if (!name) return { ok: false, error: 'MISSING_NAME' };
  return { ok: true, value: { name, processedAt: 2129 } };
}
