#!/bin/bash

# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Usage: ./test.sh

# Define the Prolog executable and the test directory
PROLOG="./flp23-log"
TEST_DIR="tests"

# Initialize counters for passing and failing tests
PASS=0
FAIL=0

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m' # No Color

make

# Loop through all .in files in the test directory
for INPUT_FILE in ${TEST_DIR}/*.in; do
    # Derive the output file name from the input file name
    OUTPUT_FILE="${INPUT_FILE%.in}.out"

    # Run the Prolog program with the input file and store the output in a temporary file
    TEMP_FILE=$(mktemp)
    ${PROLOG} < ${INPUT_FILE} > ${TEMP_FILE}

    # Compare the output file to the temporary file
    if diff -q ${OUTPUT_FILE} ${TEMP_FILE} >/dev/null 2>&1; then
        echo -e "${GREEN}${INPUT_FILE}: PASS${NOCOLOR}"
        ((PASS++))
    else
        echo -e "${RED}${INPUT_FILE}: FAIL${NOCOLOR}"
        ((FAIL++))
    fi

    # Remove the temporary file
    rm ${TEMP_FILE}
done

# Print the final test results
echo "============================="
echo -e "${GREEN}Tests passed: ${PASS}${NOCOLOR}"
if [[ ${FAIL} -ne 0 ]]; then
  echo -e "${RED}Tests failed: ${FAIL}${NOCOLOR}"
fi
