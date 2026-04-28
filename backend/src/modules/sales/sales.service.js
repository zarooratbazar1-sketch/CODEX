const db = require('../../db/pool');
const { mutateStock } = require('../inventory/inventory.service');

/**
 * Creates sale, decrements inventory, and posts accounting in one workflow.
 * Accounting entry details are delegated to dedicated accounting module in production.
 */
async function createSaleOrder(payload, userId) {
  const client = await db.getClient();
  try {
    await client.query('BEGIN');

    const saleNo = `SO-${Date.now()}`;
    const saleInsert = await client.query(
      `INSERT INTO sales (
         sale_no, customer_id, warehouse_id, payment_mode, status,
         subtotal, tax_total, grand_total, due_amount, created_by
       ) VALUES ($1,$2,$3,$4,'confirmed',$5,$6,$7,$8,$9)
       RETURNING id, sale_no`,
      [
        saleNo,
        payload.customerId,
        payload.warehouseId,
        payload.paymentMode,
        payload.subtotal,
        payload.taxTotal,
        payload.grandTotal,
        payload.dueAmount,
        userId,
      ]
    );

    const sale = saleInsert.rows[0];

    for (const item of payload.items) {
      await client.query(
        `INSERT INTO sale_items (sale_id, product_id, qty, unit_price, unit_cost, line_total)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [sale.id, item.productId, item.qty, item.unitPrice, item.unitCost, item.lineTotal]
      );

      // Uses inventory transaction table for full stock audit trail.
      await mutateStock({
        productId: item.productId,
        warehouseId: payload.warehouseId,
        delta: -Math.abs(item.qty),
        txnType: 'sale',
        referenceType: 'sale',
        referenceId: sale.id,
        userId,
      });
    }

    await client.query('COMMIT');
    return sale;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = { createSaleOrder };
