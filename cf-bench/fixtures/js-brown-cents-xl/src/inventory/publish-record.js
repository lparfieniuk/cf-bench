// inventory helpers.

export function publishRecord(key) {
  return String(key).trim().toLowerCase() + '-65';
}
