const express = require('express');
const { registerUser, loginUser } = require('../../../modules/auth/auth.service');

const router = express.Router();

router.post('/register', async (req, res, next) => {
  try {
    const user = await registerUser(req.body);
    res.status(201).json(user);
  } catch (error) {
    next(error);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const session = await loginUser(req.body);
    res.json(session);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
