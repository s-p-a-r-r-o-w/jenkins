#!/bin/bash
STERLING_DIR="/opt/IBM/OMS10"
java_process="${STERLING_DIR}/jdk/bin/java"
# Function to check Java process count
get_java_process_count() {
  local count=$(pgrep -c -f "$java_process")
  echo "$count"
}
# Check Java process count
java_process_count=$(get_java_process_count)
if [ "$java_process_count" -eq 0 ]; then
    echo "ZERO"
else
    echo "NONZERO"
fi
