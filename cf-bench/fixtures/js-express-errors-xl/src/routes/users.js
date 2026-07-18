import { Router } from 'express';
import { findUser } from '../services/user-service.js';

export const usersRouter = Router();

usersRouter.get('/:id', async (req, res) => {
  try {
    const user = await findUser(req.params.id);
    if (!user) {
      res.status(404).json({ error: 'NOT_FOUND', message: 'no such user' });
      return;
    }
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: 'INTERNAL', message: e.message });
  }
});
