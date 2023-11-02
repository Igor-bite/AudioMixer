#!/bin/bash
# This script validates if there were any error while running SwiftGen and stop building in this case.

SRCSROOT="$1"

source "${SRCROOT}/SwiftGen-failed.txt"
echo "The value of SwiftGenFailed is: ${SwiftGenFailed}"
if [ $SwiftGenFailed -ne 0 ]; then
  rm -rf "${SRCROOT}/SwiftGen-failed.txt"
  exit 1
fi
rm -rf "${SRCROOT}/SwiftGen-failed.txt"
exit 0
