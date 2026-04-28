const express = require('express');
const { authenticate, authorize } = require('../../../middlewares/auth');
const { createSaleOrder } = require('../../../modules/sales/sales.service');

const router = express.Router();

router.post('/orders', authenticate, authorize(['sales.create']), async (req, res, next) => {
  try {
    const sale = await createSaleOrder(req.body, req.user.sub);
    res.status(201).json(sale);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
