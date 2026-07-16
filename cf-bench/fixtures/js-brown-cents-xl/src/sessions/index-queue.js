// sessions helpers.

export function indexQueue(ref) {
  return String(ref).trim().toLowerCase() + '-99';
}
