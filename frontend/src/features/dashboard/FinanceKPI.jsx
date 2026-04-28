import { Line } from 'react-chartjs-2';

export default function FinanceKPI({ labels = [], revenue = [], expense = [] }) {
  const data = {
    labels,
    datasets: [
      { label: 'Revenue', data: revenue, borderColor: '#0ea5e9' },
      { label: 'Expense', data: expense, borderColor: '#ef4444' },
    ],
  };

  return (
    <section>
      <h2>Financial Trend</h2>
      <Line data={data} />
    </section>
  );
}
