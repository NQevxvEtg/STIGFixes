#!/bin/bash
# V-230261
# Title: RHEL 8 Library Ownership Fix
#
# Description:
# This script remediates the security finding that RHEL 8 library files
# must be owned by the 'root' user. It searches for shared library files
# (.so*) in /lib, /lib64, /usr/lib, and /usr/lib64 that are not owned
# by root and changes their ownership.
#

echo "### RHEL 8 Library Ownership Remediation ###"
echo "Checking for shared library files not owned by 'root'..."
echo "----------------------------------------------------"

# Define the directories to search
SEARCH_DIRS="/lib /lib64 /usr/lib /usr/lib64"

# Use find to locate files that are not owned by root.
# The output is stored in a variable. The `stat` command shows the filename and its current owner.
FILES_TO_FIX=$(sudo find $SEARCH_DIRS -type f -name '*.so*' ! -user root -exec stat -c "%n (current owner: %U)" {} +)

# Check if the variable is empty. If it is, no files were found and the system is compliant.
if [ -z "$FILES_TO_FIX" ]; then
  echo "✅ Success: All shared library files in the specified directories are owned by root."
  echo "----------------------------------------------------"
  exit 0
fi

# If files were found, list them and then apply the fix.
echo "⚠️ The following files require an ownership change to 'root':"
echo "$FILES_TO_FIX"
echo ""
echo "Applying fix..."

# Execute the chown command on the files found by the initial find command.
# Using -exec is efficient for this purpose.
sudo find $SEARCH_DIRS -type f -name '*.so*' ! -user root -exec chown root {} +

echo "✅ Fix applied successfully."
echo ""

# Final verification step to ensure the fix was effective.
echo "Verifying the changes..."
RECHECK_FILES=$(sudo find $SEARCH_DIRS -type f -name '*.so*' ! -user root -exec stat -c "%n" {} +)

if [ -z "$RECHECK_FILES" ]; then
  echo "✅ Verification successful. All library files are now owned by root."
else
  echo "❌ Error: The following files could not be fixed:"
  echo "$RECHECK_FILES"
fi

echo "----------------------------------------------------"

exit 0
