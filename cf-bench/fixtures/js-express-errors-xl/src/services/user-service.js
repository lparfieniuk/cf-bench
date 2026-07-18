const USERS = { u1: { id: 'u1', name: 'Ada' } };

export async function findUser(id) {
  return USERS[id] || null;
}
