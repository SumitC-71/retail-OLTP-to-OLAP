-- ============================================================
-- RETAIL OLTP DATABASE OBJECTS
-- ============================================================
-- This file contains additional database objects to enhance the
-- Retail OLTP schema:
-- 1. Utility Functions
-- 2. Triggers
-- 3. Views
-- 4. Materialized Views
-- 5. Audit Tables
-- 6. Stored Procedures
--
-- These objects improve:
-- • Data consistency
-- • Automation
-- • Business logic enforcement
-- • Analytical reporting
-- ============================================================



-- ============================================================
-- 1. FUNCTION: Automatically Update updated_at Timestamp
-- ============================================================
-- This function ensures that the updated_at column is refreshed
-- whenever a record is modified.

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- ============================================================
-- TRIGGERS FOR updated_at AUTOMATION
-- ============================================================

CREATE TRIGGER trg_customers_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


CREATE TRIGGER trg_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


CREATE TRIGGER trg_order_items_updated_at
BEFORE UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


CREATE TRIGGER trg_stores_updated_at
BEFORE UPDATE ON stores
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();



-- ============================================================
-- 2. FUNCTION: Calculate Line Total Automatically
-- ============================================================
-- Calculates total price for each order item
-- Formula:
-- line_total = (unit_price * quantity) - discount_amount

CREATE OR REPLACE FUNCTION calculate_line_total()
RETURNS TRIGGER AS $$
BEGIN
    NEW.line_total = (NEW.unit_price * NEW.quantity) - NEW.discount_amount;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- ============================================================
-- TRIGGER: Auto Calculate Line Total
-- ============================================================

CREATE TRIGGER trg_order_items_line_total
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION calculate_line_total();



-- ============================================================
-- 3. FUNCTION: Update Order Total Amount
-- ============================================================
-- Automatically recalculates total order value whenever
-- order items are inserted, updated, or deleted.

CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN

    UPDATE orders
    SET total_amount = (
        SELECT COALESCE(SUM(line_total),0)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;



-- ============================================================
-- TRIGGER: Update Order Total
-- ============================================================

CREATE TRIGGER trg_update_order_total
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();



-- ============================================================
-- 4. FUNCTION: Reduce Inventory After Order
-- ============================================================
-- Whenever a product is ordered, reduce the inventory quantity
-- in the corresponding store.

CREATE OR REPLACE FUNCTION reduce_inventory()
RETURNS TRIGGER AS $$
BEGIN

    UPDATE inventory
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id
    AND store_id = (
        SELECT store_id FROM orders WHERE order_id = NEW.order_id
    );

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;



-- ============================================================
-- TRIGGER: Reduce Inventory After Order
-- ============================================================

CREATE TRIGGER trg_reduce_inventory
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION reduce_inventory();



-- ============================================================
-- 5. VIEW: Customer Order Summary
-- ============================================================
-- Provides aggregated order statistics for each customer.
-- Useful for dashboards and CRM analytics.

CREATE VIEW vw_customer_order_summary AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount),0) AS total_spent
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;



-- ============================================================
-- 6. VIEW: Order Details
-- ============================================================
-- Combines orders, customers, products, and order_items
-- to provide a detailed order-level report.

CREATE VIEW vw_order_details AS
SELECT
    o.order_id,
    o.order_number,
    o.order_date,
    c.first_name || ' ' || c.last_name AS customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.line_total
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id;



-- ============================================================
-- 7. MATERIALIZED VIEW: Daily Sales
-- ============================================================
-- Pre-computed sales summary for each day.
-- Useful for BI tools and dashboards.

CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT
    DATE(order_date) AS sales_date,
    COUNT(order_id) AS total_orders,
    SUM(total_amount) AS total_sales
FROM orders
GROUP BY DATE(order_date);



-- ============================================================
-- 8. MATERIALIZED VIEW: Top Selling Products
-- ============================================================
-- Identifies most frequently sold products.

CREATE MATERIALIZED VIEW mv_top_products AS
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_units_sold
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_units_sold DESC;



-- ============================================================
-- 9. AUDIT TABLE: Customer Changes
-- ============================================================
-- Stores historical logs whenever customer records change.

CREATE TABLE IF NOT EXISTS customer_audit (

    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID,
    action_type VARCHAR(20),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);



-- ============================================================
-- FUNCTION: Audit Customer Changes
-- ============================================================

CREATE OR REPLACE FUNCTION audit_customer_changes()
RETURNS TRIGGER AS $$
BEGIN

    INSERT INTO customer_audit(customer_id, action_type)
    VALUES(NEW.customer_id, TG_OP);

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;



-- ============================================================
-- TRIGGER: Log Customer Activity
-- ============================================================

CREATE TRIGGER trg_customer_audit
AFTER INSERT OR UPDATE OR DELETE
ON customers
FOR EACH ROW
EXECUTE FUNCTION audit_customer_changes();



-- ============================================================
-- 10. STORED PROCEDURE: Create Order
-- ============================================================
-- Simplifies order creation logic.
-- Returns newly generated order_id.

CREATE OR REPLACE FUNCTION create_order(
    p_customer UUID,
    p_store UUID
)
RETURNS UUID AS $$

DECLARE
    new_order UUID;

BEGIN

    INSERT INTO orders(
        customer_id,
        store_id,
        order_date,
        order_status,
        payment_status
    )
    VALUES(
        p_customer,
        p_store,
        CURRENT_TIMESTAMP,
        'pending',
        'pending'
    )
    RETURNING order_id INTO new_order;

    RETURN new_order;

END;

$$ LANGUAGE plpgsql;



-- ============================================================
-- END OF FILE
-- ============================================================
-- Additional Notes:
-- • Materialized views should be refreshed periodically
-- • Example refresh command:
--
-- REFRESH MATERIALIZED VIEW mv_daily_sales;
-- REFRESH MATERIALIZED VIEW mv_top_products;
--
-- ============================================================