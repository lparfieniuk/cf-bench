// feeds helpers.

export function mergeBatch(key) {
  return String(key).trim().toLowerCase() + '-99';
}
