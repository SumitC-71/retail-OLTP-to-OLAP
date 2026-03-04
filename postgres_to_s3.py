import psycopg2
import pandas as pd
import boto3
from io import StringIO
from datetime import date

# Get today's date to create partitioned folders in S3
# Example: load_date=2026-03-04
load_date = date.today()

try:
    # ------------------------------------------------------------
    # Step 1: Establish connection to PostgreSQL (OLTP database)
    # ------------------------------------------------------------
    conn = psycopg2.connect(
        host="localhost",
        database="retail_oltp",
        user="postgres",
        password="your_password"
    )

    # ------------------------------------------------------------
    # Step 2: Create S3 client using boto3
    # This client will allow us to upload files to the S3 bucket
    # ------------------------------------------------------------
    s3 = boto3.client('s3')

    # Name of the S3 bucket used as the data lake storage
    bucket = "retail-data-lake-sumit"

    # ------------------------------------------------------------
    # Step 3: List of OLTP tables to be extracted
    # Each table will be exported and stored in S3 RAW layer
    # ------------------------------------------------------------
    tables = [
        "customers",
        "products",
        "orders",
        "order_items",
        "payments",
        "stores",
        "inventory",
        "shipments"
    ]

    # ------------------------------------------------------------
    # Step 4: Loop through each table and extract its data
    # ------------------------------------------------------------
    for table in tables:

        # SQL query to fetch all records from the current table
        query = f"SELECT * FROM {table};"

        # Load query result into a Pandas DataFrame
        df = pd.read_sql(query, conn)

        # --------------------------------------------------------
        # Step 5: Convert DataFrame into CSV format in memory
        # StringIO acts like a temporary file stored in memory
        # --------------------------------------------------------
        csv_buffer = StringIO()
        df.to_csv(csv_buffer, index=False)

        # --------------------------------------------------------
        # Step 6: Define the S3 path where the file will be stored
        # Data is stored in RAW layer with load_date partition
        # Example path:
        # raw/products/load_date=2026-03-04/products.csv
        # --------------------------------------------------------
        s3_key = f"raw/{table}/load_date={load_date}/{table}.csv"

        # --------------------------------------------------------
        # Step 7: Upload CSV data from memory buffer to S3
        # --------------------------------------------------------
        s3.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=csv_buffer.getvalue()
        )

        # Print confirmation after successful upload
        print(f"{table} uploaded to {s3_key}")

# ------------------------------------------------------------
# Step 8: Handle any errors during database connection
# or S3 upload process
# ------------------------------------------------------------
except Exception as e:
    print("Error occurred while connecting to PostgreSQL or uploading to S3")
    print(f"Error message: {e}")

# ------------------------------------------------------------
# Step 9: Ensure database connection is closed properly
# ------------------------------------------------------------
finally:
    if 'conn' in locals():
        conn.close()