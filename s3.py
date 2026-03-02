import psycopg2
import pandas as pd
import boto3
from io import StringIO

# This file helps load data from postgres to amazon s3 lake

# PostgreSQL connection
conn = psycopg2.connect(
    host="localhost",
    database="retail_oltp",
    user="postgres",
    password="#Sumit9128"
)

# here the table_name variable refers to:
# table name in postgres, raw folder name and csv file name inside that folder
table_name = 'shipments'

query = f"select * from {table_name};"

df = pd.read_sql(query, conn)

# Convert dataframe to CSV in memory
csv_buffer = StringIO()
df.to_csv(csv_buffer, index=False)

# Upload to S3
s3 = boto3.client('s3')


# make sure that key matches the path to s3 folders
# and csv file of the same name should not be present in s3 
s3.put_object(
    Bucket='retail-data-lake-sumit',
    Key=f'raw/{table_name}/{table_name}.csv',
    Body=csv_buffer.getvalue()
)

print("Uploaded successfully to S3 Raw Zone")