#!/usr/bin/env bash

# ============================================================
# Flutter Quality Check Script
# Author: Syntax Lab Technology
# Description: Formats code, analyzes project, and sorts imports.
# ============================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Colors for readability
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

# Log file setup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="flutter_quality_log_$TIMESTAMP.log"

echo -e "${YELLOW}🔍 Starting Flutter project quality check...${NC}"
echo "Log file: $LOG_FILE"
echo "---------------------------------------------" >> "$LOG_FILE"

# Check if pubspec.yaml exists (to ensure we're in a Flutter project)
if [[ ! -f "pubspec.yaml" ]]; then
  echo -e "${RED}❌ Error: pubspec.yaml not found. Please run this script from the root of a Flutter project.${NC}" | tee -a "$LOG_FILE"
  exit 1
fi

# Function to run commands safely with error handling
run_command() {
  local CMD="$1"
  echo -e "\n${YELLOW}▶ Running: ${CMD}${NC}" | tee -a "$LOG_FILE"
  
  if eval "$CMD" >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✅ Success: ${CMD}${NC}" | tee -a "$LOG_FILE"
  else
    echo -e "${RED}❌ Failed: ${CMD}${NC}" | tee -a "$LOG_FILE"
    echo -e "${RED}Check $LOG_FILE for details.${NC}"
    exit 1
  fi
}

# Run the checks
run_command "dart format ."
run_command "flutter analyze"
run_command "flutter pub global run import_sorter:main"

echo -e "\n${GREEN}🎉 All checks completed successfully!${NC}" | tee -a "$LOG_FILE"
