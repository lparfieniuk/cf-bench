// catalog helpers.

export async function loadSnapshot(id) {
  if (!id) throw new Error('missing id');
  return { id, processedAt: 8962 };
}
