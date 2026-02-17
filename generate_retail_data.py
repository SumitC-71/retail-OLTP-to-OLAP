import csv
import random
from datetime import datetime, timedelta

# Configuration
NUM_CUSTOMERS = 100
NUM_CATEGORIES = 10
NUM_PRODUCTS = 50
NUM_STORES = 5
NUM_ORDERS = 1000
NUM_ORDER_ITEMS = 3000

# Helper for random date
def random_date(start, end):
    delta = end - start
    random_days = random.randrange(delta.days)
    return start + timedelta(days=random_days)

start_date = datetime(2023, 1, 1)
end_date = datetime(2025, 12, 31)

# -----------------------------
# Generate Customers
# -----------------------------
with open("customers.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["customer_id", "first_name", "last_name", "email", "city", "created_at"])
    
    for i in range(1, NUM_CUSTOMERS + 1):
        writer.writerow([
            i,
            f"First{i}",
            f"Last{i}",
            f"user{i}@mail.com",
            random.choice(["Mumbai", "Delhi", "Pune", "Bangalore"]),
            datetime.now()
        ])

# -----------------------------
# Generate Categories
# -----------------------------
with open("categories.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["category_id", "category_name"])
    
    for i in range(1, NUM_CATEGORIES + 1):
        writer.writerow([i, f"Category{i}"])

# -----------------------------
# Generate Products
# -----------------------------
with open("products.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["product_id", "product_name", "category_id", "price"])
    
    for i in range(1, NUM_PRODUCTS + 1):
        writer.writerow([
            i,
            f"Product{i}",
            random.randint(1, NUM_CATEGORIES),
            round(random.uniform(100, 5000), 2)
        ])

# -----------------------------
# Generate Stores
# -----------------------------
with open("stores.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["store_id", "store_name", "city", "state", "country", "created_at"])
    
    for i in range(1, NUM_STORES + 1):
        writer.writerow([
            i,
            f"Store{i}",
            random.choice(["Mumbai", "Delhi", "Pune", "Bangalore"]),
            "StateX",
            "India",
            datetime.now()
        ])

# -----------------------------
# Generate Orders
# -----------------------------
with open("orders.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["order_id", "customer_id", "store_id", "order_date", "status"])
    
    for i in range(1, NUM_ORDERS + 1):
        writer.writerow([
            i,
            random.randint(1, NUM_CUSTOMERS),
            random.randint(1, NUM_STORES),
            random_date(start_date, end_date),
            random.choice(["completed", "pending", "cancelled"])
        ])

# -----------------------------
# Generate Order Items
# -----------------------------
with open("order_items.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["order_item_id", "order_id", "product_id", "quantity", "price"])
    
    for i in range(1, NUM_ORDER_ITEMS + 1):
        product_price = round(random.uniform(100, 5000), 2)
        writer.writerow([
            i,
            random.randint(1, NUM_ORDERS),
            random.randint(1, NUM_PRODUCTS),
            random.randint(1, 5),
            product_price
        ])

print("CSV files generated successfully.")
