#!/bin/bash

# ==============================================================================
# Script: filter-data.sh
# Description: Example shell script to filter and transform raw CDC data.
#              This simulates processing data before sending to other services.
# Usage: ./filter-data.sh <input_file.json>
# ==============================================================================

if [ -z "$1" ]; then
  echo "Usage: $0 <input_file.json>"
  exit 1
fi

INPUT_FILE=$1

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File '$INPUT_FILE' not found."
  exit 1
fi

echo "--- Generating Sample Output ---"
echo "Reading from: $INPUT_FILE"

# Using grep and awk to extract operation types and document keys natively
# In a real environment, you might use 'jq' for robust JSON parsing.

echo -e "\n[Extracted Operations and IDs]:"
grep -o '"operationType":"[^"]*"' "$INPUT_FILE" | awk -F '"' '{print "Command: " $4}'
grep -o '"_id":"[^"]*"' "$INPUT_FILE" | awk -F '"' '{print "Doc ID: " $4}'

echo -e "\n[Formatting Complete Data]:"
# Sample transformation: Replacing sensitive fields (pseudo-anonymization)
sed 's/"password":"[^"]*"/"password":"***REDACTED***"/g' "$INPUT_FILE" > "filtered_$INPUT_FILE"

echo "Data processed and saved to filtered_$INPUT_FILE"
echo "--------------------------------"
