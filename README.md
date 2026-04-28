# Zaroorat Bazar Inventory & Business Management System

Enterprise-grade ecommerce ERP monorepo scaffold with a modular architecture for:

- Inventory (multi-warehouse, barcode, adjustments, low stock alerts)
- Sales (COD workflow, invoice PDF, partial payment, returns)
- Purchases (PO, GRN, supplier ledger, cost updates)
- Double-entry accounting (GL, trial balance, P&L, balance sheet)
- Courier tracking and COD reconciliation
- Reporting and executive dashboards
- JWT + role-based security

## Repository layout

```text
backend/   # Node.js + Express API with domain modules and PostgreSQL
frontend/  # React application with feature-driven modules
docs/      # Architecture, sequence diagrams, deployment playbooks
```

## Quick start (scaffold)

1. Create PostgreSQL database and run `backend/src/db/schema.sql`
2. Configure environment variables from `backend/.env.example`
3. Install backend dependencies and start API server
4. Install frontend dependencies and start React app

> This scaffold intentionally prioritizes architecture, contracts, and business-safe transaction patterns over tutorial-level CRUD snippets.
