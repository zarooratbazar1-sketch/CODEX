-- Zaroorat Bazar ERP PostgreSQL Schema
-- Normalized design with transactional integrity for inventory + double-entry accounting.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================
-- Security & Identity
-- =====================
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(100) UNIQUE NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE role_permissions (
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_id UUID NOT NULL REFERENCES roles(id),
  full_name VARCHAR(150) NOT NULL,
  email CITEXT UNIQUE NOT NULL,
  phone VARCHAR(30),
  password_hash TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================
-- Master Data
-- =====================
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(30),
  email VARCHAR(150),
  billing_address TEXT,
  shipping_address TEXT,
  credit_limit NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE suppliers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(30),
  email VARCHAR(150),
  address TEXT,
  tax_number VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE product_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES product_categories(id),
  sku VARCHAR(50) UNIQUE NOT NULL,
  barcode VARCHAR(100) UNIQUE,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  cost_price NUMERIC(14,2) NOT NULL CHECK (cost_price >= 0),
  sale_price NUMERIC(14,2) NOT NULL CHECK (sale_price >= 0),
  reorder_level NUMERIC(14,3) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE product_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  storage_provider VARCHAR(20) NOT NULL CHECK (storage_provider IN ('cloudinary', 's3')),
  storage_key TEXT NOT NULL,
  public_url TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE warehouses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(30) UNIQUE NOT NULL,
  name VARCHAR(150) NOT NULL,
  address TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE stock_balances (
  product_id UUID NOT NULL REFERENCES products(id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  on_hand NUMERIC(14,3) NOT NULL DEFAULT 0,
  reserved NUMERIC(14,3) NOT NULL DEFAULT 0,
  version INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (product_id, warehouse_id),
  CHECK (on_hand >= 0),
  CHECK (reserved >= 0)
);

CREATE TABLE inventory_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  txn_type VARCHAR(30) NOT NULL,
  qty NUMERIC(14,3) NOT NULL,
  unit_cost NUMERIC(14,2),
  reference_type VARCHAR(30) NOT NULL,
  reference_id UUID,
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_inventory_transactions_ref ON inventory_transactions(reference_type, reference_id);

-- =====================
-- Sales & Purchases
-- =====================
CREATE TABLE sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_no VARCHAR(30) UNIQUE NOT NULL,
  customer_id UUID REFERENCES customers(id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  order_source VARCHAR(30) NOT NULL DEFAULT 'manual',
  payment_mode VARCHAR(20) NOT NULL CHECK (payment_mode IN ('cod','card','bank','wallet','mixed')),
  status VARCHAR(20) NOT NULL,
  subtotal NUMERIC(14,2) NOT NULL,
  discount_total NUMERIC(14,2) NOT NULL DEFAULT 0,
  tax_total NUMERIC(14,2) NOT NULL DEFAULT 0,
  shipping_fee NUMERIC(14,2) NOT NULL DEFAULT 0,
  grand_total NUMERIC(14,2) NOT NULL,
  paid_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  due_amount NUMERIC(14,2) NOT NULL,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE sale_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  qty NUMERIC(14,3) NOT NULL CHECK (qty > 0),
  unit_price NUMERIC(14,2) NOT NULL,
  unit_cost NUMERIC(14,2) NOT NULL,
  discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(14,2) NOT NULL
);
CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);

CREATE TABLE purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_no VARCHAR(30) UNIQUE NOT NULL,
  supplier_id UUID NOT NULL REFERENCES suppliers(id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  status VARCHAR(20) NOT NULL,
  subtotal NUMERIC(14,2) NOT NULL,
  tax_total NUMERIC(14,2) NOT NULL DEFAULT 0,
  freight_total NUMERIC(14,2) NOT NULL DEFAULT 0,
  grand_total NUMERIC(14,2) NOT NULL,
  paid_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  due_amount NUMERIC(14,2) NOT NULL,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE purchase_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_id UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  qty NUMERIC(14,3) NOT NULL CHECK (qty > 0),
  unit_cost NUMERIC(14,2) NOT NULL,
  tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(14,2) NOT NULL
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  direction VARCHAR(10) NOT NULL CHECK (direction IN ('in','out')),
  entity_type VARCHAR(20) NOT NULL CHECK (entity_type IN ('customer','supplier','sale','purchase','expense','cod_settlement')),
  entity_id UUID NOT NULL,
  method VARCHAR(20) NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL,
  reference_no VARCHAR(100),
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_payments_entity ON payments(entity_type, entity_id);

CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  expense_no VARCHAR(30) UNIQUE NOT NULL,
  category VARCHAR(80) NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  expense_date DATE NOT NULL,
  vendor_name VARCHAR(150),
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================
-- Courier & COD
-- =====================
CREATE TABLE courier_shipments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id UUID NOT NULL REFERENCES sales(id),
  courier_name VARCHAR(100) NOT NULL,
  tracking_no VARCHAR(100) UNIQUE NOT NULL,
  shipment_status VARCHAR(30) NOT NULL,
  delivery_status VARCHAR(30) NOT NULL,
  cod_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cod_settlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  courier_shipment_id UUID NOT NULL REFERENCES courier_shipments(id),
  settled_amount NUMERIC(14,2) NOT NULL CHECK (settled_amount >= 0),
  settlement_date DATE NOT NULL,
  settlement_ref VARCHAR(120),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================
-- Accounting (Double Entry)
-- =====================
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(150) NOT NULL,
  account_type VARCHAR(30) NOT NULL,
  parent_id UUID REFERENCES accounts(id),
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE journal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entry_no VARCHAR(30) UNIQUE NOT NULL,
  entry_date DATE NOT NULL,
  source_type VARCHAR(30) NOT NULL,
  source_id UUID,
  description TEXT,
  posted_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE journal_lines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id),
  debit NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
  credit NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
  memo TEXT,
  CHECK ((debit = 0 AND credit > 0) OR (credit = 0 AND debit > 0))
);

CREATE TABLE accounting_periods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  period_month DATE UNIQUE NOT NULL,
  status VARCHAR(20) NOT NULL CHECK (status IN ('open','closed')),
  closed_by UUID REFERENCES users(id),
  closed_at TIMESTAMPTZ
);

-- =====================
-- Audit
-- =====================
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_user_id UUID REFERENCES users(id),
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID,
  action VARCHAR(50) NOT NULL,
  before_data JSONB,
  after_data JSONB,
  request_id VARCHAR(120),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id, created_at DESC);
