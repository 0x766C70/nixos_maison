#!/bin/bash

# Usage: ./scan_to_file.sh <scan_name>
# Example: ./scan_to_file.sh report

# Check for required argument
if [ -z "$1" ]; then
  echo "Usage: $0 <scan_name>"
  exit 1
fi

SCAN_NAME="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="/home/vlp/partages"
OUTPUT_FILE="${OUTPUT_DIR}/scan_${SCAN_NAME}_${DATE}.png"

sudo scanimage --format=png --resolution=300 --mode Color > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo "Scan complete: $OUTPUT_FILE"
else
  echo "Scanning failed."
  exit 2
fi
