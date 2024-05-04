#!/bin/bash
# Database connection details
DB_NAME="tpch"
DB_USER="postgres"
DB_HOST="localhost"
DB_PASS="0000" # Be cautious with this approach

QUERY_DIR="postgresql_queries"
RESULTS_DIR="results"

# Start monitoring CPU and memory usage, redirect output to a file
vmstat 1 > vmstat_output.txt &
VMSTAT_PID=$!

# Start monitoring disk I/O, redirect output to a file
iostat 1 > iostat_output.txt &
IOSTAT_PID=$!

# Start monitoring overall resource utilization, redirect output to a file
sar -u -r -d 1 > sar_output.txt &
SAR_PID=$!

# Check if results directory exists, if not, create it
if [ ! -d "$RESULTS_DIR" ]; then
  mkdir -p "$RESULTS_DIR"
fi

# Check if query directory exists, if not, create it
if [ ! -d "$QUERY_DIR" ]; then
  mkdir -p "$QUERY_DIR"
fi

# Initialize total execution time
TOTAL_EXEC_TIME=0

# Total number of queries
TOTAL_QUERIES=21

# Loop through all query files
for i in {1..22}
do
 if [ $i -eq 20 ]; then
   echo "Skipping Query 20..."
   continue
 fi
 echo "Executing Query $i..."
 # Capture start time
 START_TIME=$(date +%s.%N)
 # Execute the query and save the result in the specific folder
 PGPASSWORD=$DB_PASS psql -d "$DB_NAME" -U "$DB_USER" -h "$DB_HOST" -f "$QUERY_DIR/$i.sql" > "$RESULTS_DIR/result$i.txt"
 # Capture end time
 END_TIME=$(date +%s.%N)
 # Calculate execution time
 EXEC_TIME=$(echo "$END_TIME - $START_TIME" | bc)
 # Add execution time to total
 TOTAL_EXEC_TIME=$(echo "$TOTAL_EXEC_TIME + $EXEC_TIME" | bc)
 # Log execution time in the results folder
 echo "Query $i execution time: $EXEC_TIME seconds" >> "$RESULTS_DIR/query_times.log"
done

# Kill the monitoring processes
kill $VMSTAT_PID
kill $IOSTAT_PID
kill $SAR_PID

# Log total execution time
echo "Total execution time: $TOTAL_EXEC_TIME seconds" >> "$RESULTS_DIR/query_times.log"

# Calculate throughput
THROUGHPUT=$(echo "scale=2; $TOTAL_QUERIES / $TOTAL_EXEC_TIME" | bc)
echo "Throughput: $THROUGHPUT queries per second" >> "$RESULTS_DIR/query_times.log"

echo "All queries executed. Check $RESULTS_DIR/query_times.log for execution times."
