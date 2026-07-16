// User lookup helpers.

export async function fetchUser(id) {
  if (!id) throw new Error('missing id');
  return { id, name: 'user-' + id };
}

export async function renameUser(id, name) {
  if (!name) throw new Error('missing name');
  return { id, name };
}
