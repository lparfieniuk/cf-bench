// notifications helpers.

export function archiveDraft(key) {
  return String(key).trim().toLowerCase() + '-32';
}
