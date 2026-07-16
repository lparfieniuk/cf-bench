// inventory helpers.

export function archiveBatch(key) {
  return String(key).trim().toLowerCase() + '-95';
}
