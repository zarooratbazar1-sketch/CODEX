const db = require('../../db/pool');

/**
 * Atomic stock mutation with row-level locking to prevent overselling.
 * delta > 0 for incoming stock, delta < 0 for outgoing stock.
 */
async function mutateStock({ productId, warehouseId, delta, txnType, referenceType, referenceId, userId }) {
  const client = await db.getClient();
  try {
    await client.query('BEGIN');

    await client.query(
      `INSERT INTO stock_balances (product_id, warehouse_id, on_hand, reserved)
       VALUES ($1, $2, 0, 0)
       ON CONFLICT (product_id, warehouse_id) DO NOTHING`,
      [productId, warehouseId]
    );

    const bal = await client.query(
      `SELECT on_hand, reserved FROM stock_balances
       WHERE product_id = $1 AND warehouse_id = $2
       FOR UPDATE`,
      [productId, warehouseId]
    );

    const row = bal.rows[0];
    const nextOnHand = Number(row.on_hand) + Number(delta);
    if (nextOnHand < Number(row.reserved)) {
      throw new Error('Insufficient available stock');
    }

    await client.query(
      `UPDATE stock_balances
       SET on_hand = $3, version = version + 1, updated_at = NOW()
       WHERE product_id = $1 AND warehouse_id = $2`,
      [productId, warehouseId, nextOnHand]
    );

    await client.query(
      `INSERT INTO inventory_transactions
      (product_id, warehouse_id, txn_type, qty, reference_type, reference_id, created_by)
      VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [productId, warehouseId, txnType, delta, referenceType, referenceId || null, userId]
    );

    await client.query('COMMIT');
    return { productId, warehouseId, onHand: nextOnHand };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = { mutateStock };
