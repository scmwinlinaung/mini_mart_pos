-- Mini Mart POS Database Schema

-- 1. Roles (Admin, Cashier, Manager)
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name varchar(15) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Users (Staff login)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username varchar(50) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL, -- Store BCrypt/Argon2 hash, not plain text
    full_name varchar(50),
    role_id INT REFERENCES roles(role_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Categories (Beverages, Snacks, Home)
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name varchar(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Suppliers (Who you buy from)
CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    company_name varchar(50) NOT NULL,
    contact_name varchar(50),
    phone_number varchar(15),
    email varchar(254),
    address TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Unit Types (Standardized units of measurement) - MOVED BEFORE PRODUCTS
CREATE TABLE unit_types (
    unit_id SERIAL PRIMARY KEY,
    unit_code varchar(50) NOT NULL UNIQUE, -- 'PCS', 'KG', 'L', etc.
    unit_name varchar(50) NOT NULL, -- 'Pieces', 'Kilograms', 'Liters'
    is_weighted BOOLEAN DEFAULT FALSE, -- For barcode scales (weight-based items)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Products (The core table for Barcode Scanners)
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    category_id INT REFERENCES categories(category_id),
    supplier_id INT REFERENCES suppliers(supplier_id), -- Preferred supplier
    unit_type_id INT REFERENCES unit_types(unit_id), -- Default unit for this product

    -- BARCODE: The most critical field for your scanner
    barcode varchar(50) UNIQUE NOT NULL,

    product_name varchar(50) NOT NULL,
    description TEXT,

    -- MONEY AS INT: Stored in cents/smallest unit
    cost_price INT DEFAULT 0,
    sell_price INT NOT NULL,

    -- INVENTORY TRACKING
    stock_quantity INT DEFAULT 0,
    reorder_level INT DEFAULT 10, -- Alert when stock is low

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Customers (Optional for Walk-in, Required for Loyalty)
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    phone_number varchar(15) UNIQUE,
    full_name varchar(50),
    address TEXT,
    loyalty_points INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Sales (Single transaction record with simplified structure)
CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    invoice_no varchar(50) UNIQUE NOT NULL, -- e.g., 'INV-20231025-001'
    user_id INT REFERENCES users(user_id), -- Cashier
    customer_id INT REFERENCES customers(customer_id), -- Nullable for walk-ins

    -- PRODUCT REFERENCE
    product_id INT REFERENCES products(product_id),
    unit_type_id INT REFERENCES unit_types(unit_id),
    barcode varchar(50) NOT NULL, -- Denormalized for performance and receipts

    -- TRANSACTION DETAILS
    product_name varchar(50) NOT NULL, -- Snapshot for receipts/history
    quantity INT NOT NULL DEFAULT 1,

    -- SNAPSHOT PRICES: Store price at moment of sale (in case product price changes later)
    unit_price INT NOT NULL, -- Individual unit price
    total_price INT NOT NULL, -- (quantity * unit_price)

    -- MONEY CALCULATIONS
    tax_amount INT DEFAULT 0,
    discount_amount INT DEFAULT 0,
    grand_total INT NOT NULL, -- (total_price + tax_amount - discount_amount)

    payment_method TEXT CHECK (payment_method IN ('CASH', 'CARD', 'QR', 'CREDIT')),
    payment_status TEXT DEFAULT 'PAID' CHECK (payment_status IN ('PAID', 'PENDING', 'REFUNDED')),

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Stock Ledger
CREATE TABLE stock_movements (
    movement_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id),
    user_id INT REFERENCES users(user_id),

    movement_type TEXT CHECK (movement_type IN ('SALE', 'PURCHASE', 'RETURN', 'ADJUSTMENT')),
    quantity INT NOT NULL, -- Positive for adding stock, Negative for removing

    notes TEXT, -- e.g. "Invoice #123" or "Sale #99"
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Purchases (Stock coming in)
CREATE TABLE purchases (
    purchase_id SERIAL PRIMARY KEY,
    supplier_id INT REFERENCES suppliers(supplier_id),
    user_id INT REFERENCES users(user_id),

    supplier_invoice_no varchar(50),
    total_amount INT DEFAULT 0,
    status TEXT DEFAULT 'RECEIVED', -- 'PENDING', 'RECEIVED'

    purchase_date TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Purchase Items
CREATE TABLE purchase_items (
    item_id SERIAL PRIMARY KEY,
    purchase_id INT REFERENCES purchases(purchase_id),
    product_id INT REFERENCES products(product_id),

    quantity INT NOT NULL,
    buy_price INT NOT NULL, -- Cost per unit
    expiry_date DATE, -- Critical for Mini Marts

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Expense Categories
CREATE TABLE expense_categories (
    category_id SERIAL PRIMARY KEY,
    category_name TEXT NOT NULL, -- 'Rent', 'Utilities', 'Salary'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. Expenses
CREATE TABLE expenses (
    expense_id SERIAL PRIMARY KEY,
    category_id INT REFERENCES expense_categories(category_id),
    user_id INT REFERENCES users(user_id),

    title TEXT NOT NULL,
    description TEXT,

    amount INT NOT NULL, -- Money as Int
    expense_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PERFORMANCE INDEXES - Create after all tables are created

-- Index for fast barcode lookups - critical for scanner performance
CREATE INDEX idx_products_barcode ON products(barcode);

-- Additional performance indexes for reporting and queries
CREATE INDEX idx_sales_date ON sales(created_at);
CREATE INDEX idx_sales_user ON sales(user_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_barcode ON sales(barcode);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_date ON stock_movements(created_at);

-- HELPER VIEWS FOR REPORTING

-- View: Daily Sales Summary
CREATE VIEW daily_sales_summary AS
SELECT
    DATE(created_at) as sale_date,
    COUNT(*) as total_transactions,
    SUM(grand_total) as total_sales,
    SUM(quantity) as total_items_sold,
    AVG(grand_total) as average_transaction_value
FROM sales
WHERE payment_status = 'PAID'
GROUP BY DATE(created_at)
ORDER BY sale_date DESC;

-- View: Product Performance
CREATE VIEW product_performance AS
SELECT
    p.product_id,
    p.product_name,
    p.barcode,
    COUNT(s.sale_id) as times_sold,
    COALESCE(SUM(s.quantity), 0) as total_quantity_sold,
    COALESCE(SUM(s.grand_total), 0) as total_revenue
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id AND s.payment_status = 'PAID'
GROUP BY p.product_id, p.product_name, p.barcode
ORDER BY total_revenue DESC;

-- View: Low Stock Alert
CREATE VIEW low_stock_alert AS
SELECT
    product_id,
    product_name,
    barcode,
    stock_quantity,
    reorder_level,
    (reorder_level - stock_quantity) as needed_to_reorder
FROM products
WHERE stock_quantity <= reorder_level AND is_active = TRUE
ORDER BY needed_to_reorder DESC;

-- AUTOMATION TRIGGERS

-- A. Trigger: Auto-Deduct Stock on Sale
CREATE OR REPLACE FUNCTION fn_process_sale_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Deduct from Product Inventory
    UPDATE products
    SET stock_quantity = stock_quantity - NEW.quantity,
        updated_at = NOW()
    WHERE product_id = NEW.product_id;

    -- 2. Add entry to Stock Ledger
    INSERT INTO stock_movements (product_id, user_id, movement_type, quantity, notes, created_at)
    VALUES (NEW.product_id, NEW.user_id, 'SALE', -NEW.quantity, 'Sale ID: ' || NEW.sale_id || ' - ' || NEW.product_name, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sale_stock
AFTER INSERT ON sales
FOR EACH ROW
WHEN (NEW.payment_status = 'PAID') -- Only deduct stock for paid sales
EXECUTE FUNCTION fn_process_sale_stock();

-- B. Trigger: Auto-Add Stock on Purchase
CREATE OR REPLACE FUNCTION fn_process_purchase_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Add to Product Inventory
    UPDATE products
    SET stock_quantity = stock_quantity + NEW.quantity,
        cost_price = NEW.buy_price -- Optional: Update latest cost price
    WHERE product_id = NEW.product_id;

    -- 2. Add entry to Stock Ledger
    INSERT INTO stock_movements (product_id, user_id, movement_type, quantity, notes, created_at)
    VALUES (NEW.product_id, NEW.user_id, 'PURCHASE', NEW.quantity, 'Stock In Purchase ID: ' || NEW.purchase_id, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_purchase_stock
AFTER INSERT ON purchase_items
FOR EACH ROW
EXECUTE FUNCTION fn_process_purchase_stock();

-- Insert default data
INSERT INTO roles (role_name) VALUES
('စီမံခန့်ခွဲသူ'),
('မန်နေဂျာ'),
('ငွေကိုင်');

-- Create a default admin user (password: admin123 - should be changed in production)
INSERT INTO users (username, password_hash, full_name, role_id, is_active) VALUES
('admin', '7fcf4ba391c48784edde599889d6e3f1e47a27db36ecc050cc92f259bfac38afad2c68a1ae804d77075e8fb722503f3eca2b2c1006ee6f6c7b7628cb45fffd1d', 'စနစ်တက်စီမံခန့်ခွဲသူ', 1, true);

-- Insert default categories
INSERT INTO categories (category_name) VALUES
('အချိုရည်များ'),
('စားသောက်ကုန်ပစ္စည်းများ'),
('အိမ်သုံးပစ္စည်းများ'),
('လျှပ်စစ်ပစ္စည်းများ'),
('ကိုယ်ရေးကိုယ်တာသုံးပစ္စည်းများ'),
('ထမင်းအသုပ်များ'),
('စာရေးကိရိယာပစ္စည်းများ');

-- Insert default unit types
INSERT INTO unit_types (unit_code, unit_name, is_weighted) VALUES
('PCS', 'အရေအတွက်', FALSE),
('KG', 'ကီလိုဂရမ်', TRUE),
('G', 'ဂရမ်', TRUE),
('L', 'လီတာ', FALSE),
('ML', 'မီလီလီတာ', FALSE),
('M', 'မီတာ', FALSE),
('CM', 'စင်တီမီတာ', FALSE),
('BOX', 'ဘူး', FALSE),
('PACK', 'အထုပ်', FALSE),
('BOTTLE', 'ဘူးကြီး', FALSE),
('CAN', 'အမှုန့်', FALSE),
('BAG', 'အိတ်', FALSE);

-- Insert sample suppliers
INSERT INTO suppliers (company_name, contact_name, phone_number, address) VALUES
('မြန်မာ့စီးပွားရေးကုမ္ပဏီ', 'ဦးအောင်မြင့်', '09-123456789', 'မန္တလေးမြို့၊ ချမ်းအေးသာဇံ'),
('စက်မှုလက်မှုထုတ်ကုန်များ', 'ဒေါ်နန်းနွယ်ဝင်း', '09-987654321', 'ရန်ကုန်မြို့၊ လမ်းမတော်'),
('အစားအသောက်ဖြန့်ချီရေး', 'ဦးကျော်ဇော', '09-456789012', 'နေပြည်တော်မြို့'),
('လျှပ်စစ်ပစ္စည်းကုမ္ပဏီ', 'ဦးမင်းထွန်း', '09-789012345', 'မန္တလေးမြို့၊ အောင်မြေသာစံ'),
('ဆေးဝါးနှင့်ကျန်းမာရေး', 'ဒေါက်တာခင်ခင်မြ', '09-234567890', 'ရန်ကုန်မြို့၊ ဗိုလ်တထောင်'),
('စားသောက်ကုန်ပစ္စည်းများ', 'ဦးဇော်ဝင်း', '09-345678901', 'ရန်ကုန်မြို့၊ သင်္ဃန်းကျွန်း'),
('အိမ်သုံးပစ္စည်းအရောင်း', 'ဒေါ်မြမြစိန်', '09-567890123', 'မန္တလေးမြို့၊ ပြည်ကြီးမဏေ'),
('ကုန်းလမ်းပို့ဆောင်ရေး', 'ဦးထွန်းထွန်း', '09-678901234', 'ရန်ကုန်မြို့၊ လှည်းတန်း'),
('ရွှေစည်သာထုတ်လုပ်ရေး', 'ဦးစိန်စိန်', '09-890123456', 'မန္တလေးမြို့၊ ဇော်ဂျီ');