# Phase 3–10 Implementation Blueprint

## Phase 3 — Authentication & Security
- Registration/login with bcrypt hashing and JWT tokens.
- Permission middleware protects sensitive endpoints.
- Add `express-rate-limit`, `helmet`, and request schema validation (Joi/Zod).
- Financial APIs require idempotency key header and store processed keys table.

## Phase 4 — Inventory Module
- SKU format: `ZB-{CATEGORY}-{YYMM}-{SEQ}`.
- Image upload flow:
  1. API receives multipart metadata.
  2. Upload to Cloudinary/S3 via signed credential.
  3. Persist metadata in `product_images`.
- Multi-warehouse quantity from `stock_balances`.
- Low-stock job runs hourly, publishes notifications to Redis queue/email.

## Phase 5 — Sales Module
- COD orders create `sales` + `courier_shipments` records with payable COD value.
- Partial payment updates `payments` and recalculates `due_amount`.
- Return creates reverse stock transaction + credit note journal entry.
- Invoice PDFs generated with `pdfmake` or `puppeteer` server-side template.

## Phase 6 — Purchase Module
- Purchase order lifecycle: `draft -> approved -> received -> invoiced`.
- GRN post increments stock and updates weighted average cost.
- Purchase return decrements stock and posts supplier credit.

## Phase 7 — Accounting
- Auto-posting matrix maps operations to account debits/credits.
- Trial balance uses aggregated journal lines by account.
- Month closing:
  - Check all journals balanced.
  - Lock accounting period.
  - Carry forward retained earnings.

## Phase 8 — Courier & COD
- Webhook endpoint for shipment status sync (`in_transit`, `delivered`, `rto`).
- COD settlement process compares courier remittance vs expected COD per delivered shipments.

## Phase 9 — Reports & Analytics
- Materialized views for heavy reporting queries (monthly profitability).
- Dashboard cards:
  - Revenue today
  - Gross margin month-to-date
  - Outstanding receivables
  - Payables due
- Frontend charts can use Chart.js/Recharts.

## Phase 10 — Deployment & DevOps
- Deploy API behind Nginx reverse proxy + TLS.
- Use Docker multi-stage builds for frontend and backend.
- CI pipeline: lint, unit tests, migration dry-run, build, deploy.
- Backups:
  - Nightly `pg_dump` full backup
  - WAL archiving for point-in-time recovery
- Monitoring:
  - Prometheus metrics endpoint
  - Grafana dashboards
  - Structured JSON logs to ELK/Loki
