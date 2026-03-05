TABLES = [

    {
        "table_name": "customers",
        "timestamp_column": "updated_at",
        "primary_key": "customer_id"
    },

    {
        "table_name": "stores",
        "timestamp_column": "updated_at",
        "primary_key": "store_id"
    },

    {
        "table_name": "products",
        "timestamp_column": "updated_at",
        "primary_key": "product_id"
    },

    {
        "table_name": "orders",
        "timestamp_column": "updated_at",
        "primary_key": "order_id"
    },

    {
        "table_name": "order_items",
        "timestamp_column": "updated_at",
        "primary_key": "order_item_id"
    },

    {
        "table_name": "payments",
        "timestamp_column": "created_at",
        "primary_key": "payment_id"
    },

    {
        "table_name": "inventory",
        "timestamp_column": "last_updated",
        "primary_key": "inventory_id"
    },

    {
        "table_name": "shipments",
        "timestamp_column": "created_at",
        "primary_key": "shipment_id"
    }
]