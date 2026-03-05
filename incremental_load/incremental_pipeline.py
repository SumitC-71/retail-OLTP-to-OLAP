import psycopg2
import pandas as pd
import boto3
from io import StringIO
from datetime import date


import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from config.tables_config import TABLES


# ---------- CONFIG ----------
DB_CONFIG = {
    "host": "localhost",
    "database": "retail_oltp",
    "user": "postgres",
    "password": "your_password"
}

S3_BUCKET = "retail-data-lake-sumit"
S3_BASE_PATH = "raw"

METADATA_FOLDER = "metadata"


# ---------- POSTGRES CONNECTION ----------
conn = psycopg2.connect(**DB_CONFIG)

# ---------- S3 CLIENT ----------
s3 = boto3.client("s3")



for table in TABLES:

    table_name = table["table_name"]
    timestamp_col = table["timestamp_column"]

    print(f"\nProcessing table: {table_name}")

    metadata_file = f"{METADATA_FOLDER}/{table_name}.txt"

    # ---------- READ METADATA ----------
    last_timestamp = "1900-01-01 00:00:00"

    if os.path.exists(metadata_file):

        with open(metadata_file, "r") as f:
            lines = f.readlines()

        for line in lines:
            if line.startswith("last_timestamp"):
                last_timestamp = line.strip().split("=")[1]

    print("Last timestamp:", last_timestamp)

    # ---------- INCREMENTAL QUERY ----------
    query = f"""
    SELECT *
    FROM {table_name}
    WHERE {timestamp_col} > '{last_timestamp}'
    """

    df = pd.read_sql(query, conn)

    if df.empty:
        print("No new records found.")
        continue

    # ---------- NEW MAX TIMESTAMP ----------
    new_timestamp = df[timestamp_col].max()

    # ---------- CONVERT TO CSV ----------
    csv_buffer = StringIO()
    df.to_csv(csv_buffer, index=False)

    # ---------- S3 PATH ----------
    today = date.today()

    s3_key = f"{S3_BASE_PATH}/{table_name}/load_date={today}/{table_name}.csv"
    try:
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=csv_buffer.getvalue()
        )
    except Exception as e:
        print('Access Denied')
        print('Connection closed')
        conn.close()
        break

    print(f"Uploaded to S3: {s3_key}")

    # ---------- UPDATE METADATA ----------
    with open(metadata_file, "w") as f:
        f.write(f"load_date={today}\n")
        f.write(f"last_timestamp={new_timestamp}")

    print("Metadata updated")


# ---------- CLOSE CONNECTION ----------
conn.close()

print("\nIncremental load completed")


print('Done')
'''
'''