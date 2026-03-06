# Retail Data Engineering Project

### OLTP → Data Lake (S3) → Analytical Pipeline

## 1. Project Overview

This project demonstrates the process of building a **data pipeline that extracts data from an OLTP database and stores it in a Data Lake for further analytical processing**.

The goal is to simulate a **retail data platform** where transactional data from a PostgreSQL OLTP system is extracted and stored in **AWS S3** in a structured format to support **analytics and downstream processing**.

The project focuses on the **data engineering pipeline**, including:

* OLTP database design
* Data extraction
* Data lake storage architecture
* Incremental data loading
* Data validation
* Preparation for transformation using PySpark

---

# 2. High Level Architecture

```
PostgreSQL (OLTP Database)
        │
        │ Extract (Python + Pandas)
        ▼
Raw Data Files
        │
        ▼
Amazon S3 Data Lake
        │
        ▼
Future Processing (PySpark / Analytics Layer)
```

---

# 3. Technologies Used

| Technology        | Purpose                                          |
| ----------------- | ------------------------------------------------ |
| PostgreSQL        | OLTP transactional database                      |
| Python            | Data extraction pipeline                         |
| Pandas            | Data processing and transformation before upload |
| psycopg2          | PostgreSQL database connectivity                 |
| boto3             | AWS SDK used to upload data to S3                |
| AWS S3            | Data Lake storage                                |
| CSV format        | Initial raw data storage                         |
| PySpark (planned) | Data transformation and analytics                |
| Parquet (planned) | Optimized columnar storage                       |

---

# 4. Project Structure

```
retail-data-engineering/
│
├── extraction_scripts/
│      extract_to_s3.py
│
├── metadata/
│      customers.txt
│      orders.txt
│      products.txt
│
├── s3_bucket_structure/
│
│   retail-data-lake/
│       raw/
│           customers/
│               load_date=YYYY-MM-DD/
│
│           orders/
│               load_date=YYYY-MM-DD/
│
│           products/
│               load_date=YYYY-MM-DD/
│
└── README.md
```

---

# 5. OLTP Database Schema

The PostgreSQL database simulates a **retail transaction system**.

Database Name:

```
retail_oltp
```

Main entities include:

* Customers
* Orders
* Products
* Order Items
* Payments
* Inventory

---

# 6. Database Tables and Row Counts

*(Row counts are assumed for now and can be updated later)*

| Table Name  | Description                       | Total Rows |
| ----------- | --------------------------------- | ---------- |
| customers   | Stores customer information       | 10,000     |
| products    | Stores product catalog details    | 5,000      |
| orders      | Stores order transactions         | 25,000     |
| order_items | Stores individual items per order | 75,000     |
| payments    | Stores payment details            | 25,000     |
| inventory   | Stores product stock levels       | 5,000      |

---

# 7. Data Extraction Pipeline

A **Python-based extraction pipeline** was developed to move data from PostgreSQL to S3.

Steps performed:

1. Connect to PostgreSQL using **psycopg2**
2. Query the required tables
3. Load the data into **Pandas DataFrames**
4. Convert the data into **CSV format**
5. Upload the files to **Amazon S3 using boto3**

Example flow:

```
PostgreSQL Table
      │
      ▼
SQL Query
      │
      ▼
Pandas DataFrame
      │
      ▼
CSV File
      │
      ▼
Upload to Amazon S3
```

---

# 8. Incremental Loading

Instead of extracting the full dataset every time, the pipeline supports **incremental loading**.

### What is Incremental Loading?

Incremental loading means:

> Only new or updated records since the last extraction are loaded.

This improves:

* Performance
* Cost
* Scalability

---

### Incremental Logic Used

The pipeline tracks the **last extraction timestamp** using a metadata file.

Example metadata file:

```
customers.txt
```

Contents:

```
load_date=2026-03-06
last_timestamp=2026-02-23 19:03:56.176088
```

Extraction query example:

```sql
SELECT *
FROM customers
WHERE updated_at > '2026-02-23 19:03:56.176088';
```

After successful extraction, the metadata file is updated with the **latest timestamp**.

---

# 9. S3 Data Lake Structure

The S3 bucket follows a **partitioned structure based on load date**.

Example:

```
s3://retail-data-lake/

raw/

   customers/
       load_date=2026-03-06/
           customers.csv

   orders/
       load_date=2026-03-06/
           orders.csv

   products/
       load_date=2026-03-06/
           products.csv
```

Benefits:

* Organized data storage
* Easier querying
* Supports future partition-based analytics

---

# 10. Data Validation

Basic validation checks are performed before uploading data to S3.

Examples:

* Row count validation
* Null value checks
* Timestamp verification
* Data format validation

---

# 11. Work Completed So Far

Completed components:

* ✔ OLTP database design in PostgreSQL
* ✔ Retail schema creation
* ✔ Data population
* ✔ Python extraction scripts
* ✔ PostgreSQL connectivity
* ✔ S3 bucket setup
* ✔ Data lake folder structure
* ✔ Initial full data load
* ✔ Incremental load logic
* ✔ Metadata tracking for incremental extraction

---

# 12. Work in Progress

Upcoming tasks:

* PySpark data transformation pipeline
* Data cleaning and standardization
* Convert CSV files to **Parquet format**
* Build **curated analytics datasets**
* Implement **data quality framework**
* Implement **data partitioning and optimization**

---

# 13. Future Enhancements

Planned improvements:

* Airflow for workflow orchestration
* Spark-based ETL transformations
* Data warehouse layer (Redshift / Snowflake)
* Analytics dashboards
* Automated monitoring and alerting

---

# 14. Summary

This project demonstrates a **real-world data engineering workflow** where transactional data from a relational database is ingested into a data lake using a scalable pipeline.

The system is designed to support:

* Incremental data ingestion
* Scalable storage
* Future analytical processing

This forms the foundation for building a **modern data platform for retail analytics**.


