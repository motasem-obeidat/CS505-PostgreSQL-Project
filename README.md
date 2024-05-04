# CS505-001: Intermediate Tops in Database Systems (Spring 2024)
## Project: Performance benchmarking | PostgreSQL
This README outlines the steps to install PostgreSQL, generate and load TPC-H benchmark data into PostgreSQL, and monitor system performance during SQL query execution. This setup uses an Ubuntu operating system on a Parallels virtual machine running on an M3 MacBook configured with an 8-core CPU and 8 GB of RAM.

# Installation instructions

## Step 1: Install PostgreSQL

1. **Update your system's package index:**
   ```bash
   sudo apt update
   sudo apt upgrade
   ```

2. **Install PostgreSQL and its contrib package:**
   ```bash
   sudo apt install postgresql postgresql-contrib
   ```

3. **Start and enable PostgreSQL:**
   ```bash
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

## Step 2: Install and Configure Sysstat

1. **Install sysstat:**
   ```bash
   sudo apt-get install sysstat
   ```

2. **Enable sysstat to collect system performance data:**
   ```bash
   sudo nano /etc/default/sysstat
   # Change ENABLED="false" to ENABLED="true"
   # Save and exit
   sudo service sysstat restart
   ```

## Step 3: Install TPC-H Tools

1. **Install necessary packages:**
   ```bash
   sudo apt install git make gcc
   ```

2. **Clone and build TPC-H DBGen:**
   ```bash
   git clone https://github.com/electrum/tpch-dbgen.git
   cd tpch-dbgen
   make
   ```

## Step 4: Generate TPC-H Data Sets

   Generate data for testing (where "1" represents a 1 GB data size):
   ```bash
   ./dbgen -s 1
   ```

## Step 5: Create Tables for TPC-H Data

1. **Start PostgreSQL and Change the PostgreSQL user password:**
   ```sql
   sudo -u postgres psql
   ALTER USER postgres WITH PASSWORD '0000';
   ```

2. **Create the TPC-H database and switch to it:**
   ```sql
   CREATE DATABASE tpch;
   \c tpch
   ```

3. **Create tables for TPC-H data:**
   ```sql
   CREATE TABLE nation (
       n_nationkey  INTEGER not null,
       n_name       CHAR(25) not null,
       n_regionkey  INTEGER not null,
       n_comment    VARCHAR(152)
   );

   CREATE TABLE region (
       r_regionkey  INTEGER not null,
       r_name       CHAR(25) not null,
       r_comment    VARCHAR(152)
   );

   CREATE TABLE part (
       p_partkey     BIGINT not null,
       p_name        VARCHAR(55) not null,
       p_mfgr        CHAR(25) not null,
       p_brand       CHAR(10) not null,
       p_type        VARCHAR(25) not null,
       p_size        INTEGER not null,
       p_container   CHAR(10) not null,
       p_retailprice DOUBLE PRECISION not null,
       p_comment     VARCHAR(23) not null
   );   

   CREATE TABLE supplier (
       s_suppkey     BIGINT not null,
       s_name        CHAR(25) not null,
       s_address     VARCHAR(40) not null,
       s_nationkey   INTEGER not null,
       s_phone       CHAR(15) not null,
       s_acctbal     DOUBLE PRECISION not null,
       s_comment     VARCHAR(101) not null
   );

   CREATE TABLE partsupp (
       ps_partkey     BIGINT not null,
       ps_suppkey     BIGINT not null,
       ps_availqty    BIGINT not null,
       ps_supplycost  DOUBLE PRECISION  not null,
       ps_comment     VARCHAR(199) not null
   );

   CREATE TABLE customer (
       c_custkey     BIGINT not null,
       c_name        VARCHAR(25) not null,
       c_address     VARCHAR(40) not null,
       c_nationkey   INTEGER not null,
       c_phone       CHAR(15) not null,
       c_acctbal     DOUBLE PRECISION   not null,
       c_mktsegment  CHAR(10) not null,
       c_comment     VARCHAR(117) not null
   );

   CREATE TABLE orders (
       o_orderkey       BIGINT not null,
       o_custkey        BIGINT not null,
       o_orderstatus    CHAR(1) not null,
       o_totalprice     DOUBLE PRECISION not null,
       o_orderdate      DATE not null,
       o_orderpriority  CHAR(15) not null,  
       o_clerk          CHAR(15) not null, 
       o_shippriority   INTEGER not null,
       o_comment        VARCHAR(79) not null
   );

   CREATE TABLE lineitem (
       l_orderkey    BIGINT not null,
       l_partkey     BIGINT not null,
       l_suppkey     BIGINT not null,
       l_linenumber  BIGINT not null,
       l_quantity    DOUBLE PRECISION not null,
       l_extendedprice  DOUBLE PRECISION not null,
       l_discount    DOUBLE PRECISION not null,
       l_tax         DOUBLE PRECISION not null,
       l_returnflag  CHAR(1) not null,
       l_linestatus  CHAR(1) not null,
       l_shipdate    DATE not null,
       l_commitdate  DATE not null,
       l_receiptdate DATE not null,
       l_shipinstruct CHAR(25) not null,
       l_shipmode     CHAR(10) not null,
       l_comment      VARCHAR(44) not null
   );
   
   ```

## Step 6: Prepare Data for PostgreSQL (Open a New Terminal (Keep the Previous One Open))

   **Move TPC-H generated `.tbl` files to PostgreSQL accessible directory and prepare them:**
   ```bash
   sudo cp /home/parallels/tpch-dbgen/*.tbl /var/lib/postgresql/
   sudo chown postgres:postgres /var/lib/postgresql/*.tbl

   # Remove the vertical bar (|) at the end of each line in each `.tbl` file
   sudo sed 's/|$//' /var/lib/postgresql/customer.tbl > /tmp/customer_fixed.tbl
   sudo mv /tmp/customer_fixed.tbl /var/lib/postgresql/customer_fixed.tbl
   sudo chown postgres:postgres /var/lib/postgresql/customer_fixed.tbl

   sudo sed 's/|$//' /var/lib/postgresql/orders.tbl > /tmp/orders_fixed.tbl
   sudo mv /tmp/orders_fixed.tbl /var/lib/postgresql/orders_fixed.tbl
   sudo chown postgres:postgres /var/lib/postgresql/orders_fixed.tbl

   sudo sed 's/|$//' /var/lib/postgresql/lineitem.tbl > /tmp/lineitem_fixed.tbl
   sudo mv /tmp/lineitem_fixed.tbl /var/lib/postgresql/lineitem_fixed.tbl
   sudo chown postgres:postgres /var/lib/postgresql/lineitem_fixed.tbl

   sudo sed 's/|$//' /var/lib/postgresql/nation.tbl > /tmp/nation_fixed.tbl
   sudo mv /tmp/nation_fixed.tbl /var/lib/postgresql/nation_fixed.tbl
   sudo chown postgres:postgres /var/lib/postgresql/nation_fixed.tbl

   sudo sed 's/|$//' /var/lib/postgresql/region.tbl > /tmp/region_fixed.tbl
   sudo mv /tmp/region_fixed.tbl /var/lib/postgresql/region_fixed.tbl
   sudo chown postgres:postgres /var/lib/postgresql/region_fixed.tbl

   sudo sed 's/|$//' /var/lib/postgresql/part.tbl > /tmp/part_fixed.tbl
   sudo mv /tmp/part_fixed.tbl /var/lib/postgresql/part_fixed.tbl
   sudo chown postgres:postgres /var/lib/postgresql/part_fixed.tbl

   sudo sed 's/|$//' /var/lib/postgresql/supplier.tbl > /tmp/supplier_fixed.tbl
   sudo mv /tmp/supplier_fixed.tbl /var/lib/postgresql/supplier_fixed.tbl
   sudo chown postgres:postgres /var/lib/postgresql/supplier_fixed.tbl

   sudo sed 's/|$//' /var/lib/postgresql/partsupp.tbl > /tmp/partsupp_fixed.tbl
   sudo mv /tmp/partsupp_fixed.tbl /var/lib/postgresql/partsupp_fixed.tbl
   sudo chown postgres:postgres /var/lib/postgresql/partsupp_fixed.tbl
   ```

## Step 7: Load Data Into PostgreSQL (Go Back to the First Terminal (the \c tpch Terminal))

   **Load data into PostgreSQL using the \COPY command:**
   ```sql
   \COPY customer FROM '/var/lib/postgresql/customer_fixed.tbl' WITH (FORMAT csv, DELIMITER '|', HEADER false, NULL 'null');

   \COPY orders FROM '/var/lib/postgresql/orders_fixed.tbl' WITH (FORMAT csv, DELIMITER '|', HEADER false, NULL 'null');

   \COPY lineitem FROM '/var/lib/postgresql/lineitem_fixed.tbl' WITH (FORMAT csv, DELIMITER '|', HEADER false, NULL 'null');

   \COPY nation FROM '/var/lib/postgresql/nation_fixed.tbl' WITH (FORMAT csv, DELIMITER '|', HEADER false, NULL 'null');

   \COPY region FROM '/var/lib/postgresql/region_fixed.tbl' WITH (FORMAT csv, DELIMITER '|', HEADER false, NULL 'null');

   \COPY part FROM '/var/lib/postgresql/part_fixed.tbl' WITH (FORMAT csv, DELIMITER '|', HEADER false, NULL 'null');

   \COPY supplier FROM '/var/lib/postgresql/supplier_fixed.tbl' WITH (FORMAT csv, DELIMITER '|', HEADER false, NULL 'null');

   \COPY partsupp FROM '/var/lib/postgresql/partsupp_fixed.tbl' WITH (FORMAT csv, DELIMITER '|', HEADER false, NULL 'null');  
   ```

## Step 8: Running `postgresql.sh` Script

1. **Created a script called `postgresql.sh` that is attached to execute SQL queries and monitor system resources:**

   **The `postgresql_queries` file includes the TPC-H benchmark SQL queries that have been modified to work with PostgreSQL.**

   **The `postgresql.sh` script handles executing queries from a specified directory and logs their execution time and system resource usage. The monitoring processes like `vmstat`, `iostat`, and `sar` are started before executing the queries and stopped afterward.**
	
   **The script also calculates and logs throughput based on total execution time and number of queries.**
   
   
2. **Usage (open a new terminal in the same location as the `postgresql.sh` file)**
   
   **Make sure to mark `postgresql.sh` as executable and run it:**
   ```bash
   chmod +x postgresql.sh
   ./postgresql.sh
   ```


This README provides a comprehensive guide for setting up a PostgreSQL database with TPC-H data and instructions for monitoring the performance of SQL queries executed against this database. Adjust paths and parameters as needed for your specific setup.
