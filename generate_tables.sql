-- ============================================
-- DATABASE: Retail OLTP Schema
-- ============================================

-- Enable UUID extension (optional but recommended)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. CUSTOMERS
-- ============================================

CREATE TABLE customers (
    customer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(30),
    date_of_birth DATE,
    gender VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_email ON customers(email);


-- ============================================
-- 2. STORES
-- ============================================

CREATE TABLE stores (
    store_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_name VARCHAR(150) NOT NULL,
    store_type VARCHAR(50) CHECK (store_type IN ('physical', 'online', 'warehouse')),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    opened_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================
-- 3. PRODUCTS
-- ============================================

CREATE TABLE products (
    product_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    brand VARCHAR(100),
    sku VARCHAR(100) UNIQUE NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    cost_price NUMERIC(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_brand ON products(brand);


-- ============================================
-- 4. ORDERS (Header Table)
-- ============================================

CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(100) UNIQUE NOT NULL,
    customer_id UUID NOT NULL,
    store_id UUID NOT NULL,
    order_date TIMESTAMP NOT NULL,
    order_status VARCHAR(50) CHECK (order_status IN ('pending', 'shipped', 'delivered', 'cancelled')),
    payment_status VARCHAR(50) CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    total_amount NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_orders_store FOREIGN KEY (store_id)
        REFERENCES stores(store_id) ON DELETE CASCADE
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_store ON orders(store_id);
CREATE INDEX idx_orders_date ON orders(order_date);


-- ============================================
-- 5. ORDER ITEMS (Line Items)
-- ============================================

CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL,
    discount_amount NUMERIC(10,2) DEFAULT 0,
    line_total NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON DELETE CASCADE
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);


-- ============================================
-- 6. PAYMENTS
-- ============================================

CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL,
    payment_method VARCHAR(50) CHECK (payment_method IN ('card', 'upi', 'cash', 'net_banking')),
    payment_amount NUMERIC(12,2) NOT NULL,
    payment_status VARCHAR(50) CHECK (payment_status IN ('initiated', 'successful', 'failed', 'refunded')),
    transaction_reference VARCHAR(255),
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON DELETE CASCADE
);

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_method ON payments(payment_method);


-- ============================================
-- 7. INVENTORY (Optional but Production-Grade)
-- ============================================

CREATE TABLE inventory (
    inventory_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL,
    store_id UUID NOT NULL,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    reorder_level INT DEFAULT 10,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_store FOREIGN KEY (store_id)
        REFERENCES stores(store_id) ON DELETE CASCADE,
    
    UNIQUE (product_id, store_id)
);

CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_store ON inventory(store_id);


-- ============================================
-- 8. SHIPMENTS (Optional Enterprise Feature)
-- ============================================

CREATE TABLE shipments (
    shipment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL,
    shipment_status VARCHAR(50) CHECK (shipment_status IN ('processing', 'shipped', 'in_transit', 'delivered')),
    carrier_name VARCHAR(100),
    tracking_number VARCHAR(255),
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON DELETE CASCADE
);

CREATE INDEX idx_shipments_order ON shipments(order_id);


\copy customers FROM 'C:\Users\mihir\Desktop\Final Year Project\csv files\customers.csv'
DELIMITER ',' CSV HEADER;

\copy stores FROM 'C:\Users\mihir\Desktop\Final Year Project\csv files\stores.csv'
DELIMITER ',' CSV HEADER;

\copy products FROM 'C:\Users\mihir\Desktop\Final Year Project\csv files\products.csv'
DELIMITER ',' CSV HEADER;

\copy orders FROM 'C:\Users\mihir\Desktop\Final Year Project\csv files\orders.csv'
DELIMITER ',' CSV HEADER;

\copy order_items FROM 'C:\Users\mihir\Desktop\Final Year Project\csv files\order_items.csv'
DELIMITER ',' CSV HEADER;

\copy payments FROM 'C:\Users\mihir\Desktop\Final Year Project\csv files\payments.csv'
DELIMITER ',' CSV HEADER;





ALTER TABLE customers 
ALTER COLUMN phone TYPE VARCHAR(30);

select * from shipments

select * from customers;
select count(*) from customers;

select * from stores;

select * from products;

select * from orders;

select * from order_items;

select * from payments;


INSERT INTO inventory (
    inventory_id,
    product_id,
    store_id,
    stock_quantity,
    reorder_level,
    last_updated
)
SELECT
    uuid_generate_v4(),
    p.product_id,
    s.store_id,
    (random() * 200)::int,
    20,
    CURRENT_TIMESTAMP
FROM products p
CROSS JOIN stores s;



select * from inventory;



INSERT INTO shipments (
    shipment_id,
    order_id,
    shipment_status,
    carrier_name,
    tracking_number,
    shipped_at,
    delivered_at,
    created_at
)
SELECT
    uuid_generate_v4(),
    o.order_id,
    'delivered',
    'BlueDart',
    'TRK-' || floor(random()*100000000)::text,
    o.order_date + INTERVAL '1 day',
    o.order_date + INTERVAL '3 days',
    CURRENT_TIMESTAMP
FROM orders o
WHERE o.order_status = 'delivered';

select * from shipments;

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'  -- change schema if needed
  AND table_name   = 'customers';

select updated_at from customers 
where updated_at > '2026-02-23 19:03:56.176088'

INSERT INTO customers 
(first_name, last_name, email, phone, date_of_birth, gender, updated_at)
VALUES
('Rahul', 'Sharma', 'rahul.sharma@test.com', '9876543210', '1995-06-12', 'Male', '2026-03-06 10:10:00'),
('Priya', 'Verma', 'priya.verma@test.com', '9123456780', '1998-09-25', 'Female', '2026-03-06 11:20:00'),
('Amit', 'Patel', 'amit.patel@test.com', '9988776655', '1993-02-18', 'Male', '2026-03-06 12:45:00');


