import { useState } from 'react';
import api from '../../services/apiClient';

export default function StockAdjustmentForm() {
  const [form, setForm] = useState({ productId: '', warehouseId: '', delta: 0, referenceType: 'manual' });

  const submit = async (event) => {
    event.preventDefault();
    await api.post('/inventory/adjustments', form);
    alert('Stock adjusted successfully');
  };

  return (
    <form onSubmit={submit}>
      <h3>Stock Adjustment</h3>
      <input placeholder="Product ID" onChange={(e) => setForm({ ...form, productId: e.target.value })} />
      <input placeholder="Warehouse ID" onChange={(e) => setForm({ ...form, warehouseId: e.target.value })} />
      <input type="number" placeholder="Delta (+/-)" onChange={(e) => setForm({ ...form, delta: Number(e.target.value) })} />
      <button type="submit">Save Adjustment</button>
    </form>
  );
}
