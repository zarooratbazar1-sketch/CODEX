const express = require('express');
const { authenticate, authorize } = require('../../../middlewares/auth');
const { mutateStock } = require('../../../modules/inventory/inventory.service');

const router = express.Router();

router.post('/adjustments', authenticate, authorize(['inventory.adjust']), async (req, res, next) => {
  try {
    const output = await mutateStock({ ...req.body, txnType: 'adjustment', userId: req.user.sub });
    res.status(201).json(output);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
