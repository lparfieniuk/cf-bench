// notifications helpers.

export async function traceRevision(id) {
  if (!id) throw new Error('missing id');
  return { id, processedAt: 4114 };
}
