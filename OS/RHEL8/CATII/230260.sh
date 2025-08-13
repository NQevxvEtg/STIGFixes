#!/bin/bash
# V-230260
# Rule Title: RHEL 8 library files must have mode 755 or less permissive.
#
# Description: This script checks for and corrects system-wide shared library 
#              files that have permissions more permissive than 0755. It removes 
#              write permissions for the 'group' and 'other' users to prevent 
#              unauthorized modification of system libraries.
#

echo "### RHEL 8 Library Permissions Check and Fix ###"
echo "Scanning for shared library files with permissions more permissive than 755..."
echo "Target directories: /lib, /lib64, /usr/lib, /usr/lib64"
echo "----------------------------------------------------------------"

# Define the directories to scan
LIB_DIRS="/lib /lib64 /usr/lib /usr/lib64"

# Find all files ending in .so (shared objects) that have write permissions for group or other (/022)
# The '-perm /022' check finds files where either the group-write bit (020) OR the other-write bit (002) is set.
INSECURE_FILES=$(sudo find $LIB_DIRS -type f -name '*.so*' -perm /022 -print)

# Check if the command found any files
if [ -z "$INSECURE_FILES" ]; then
    echo "✅ Compliance Check Passed: No library files with incorrect permissions were found."
else
    echo "⚠️ Compliance Check Failed: Found the following files with incorrect permissions:"
    
    # List the non-compliant files and their current permissions for logging purposes
    sudo find $LIB_DIRS -type f -name '*.so*' -perm /022 -exec stat -c "%n - Current Permissions: %a" {} +
    
    echo ""
    echo "Applying fix: Removing write permissions for 'group' and 'other' (chmod go-w)..."
    
    # Use the -exec option with '+' to run chmod on all found files in a single command, which is more efficient.
    sudo find $LIB_DIRS -type f -name '*.so*' -perm /022 -exec chmod go-w {} +
    
    echo ""
    echo "Verifying the fix..."
    
    # Re-run the check to ensure the fix was successful
    RECHECK_FILES=$(sudo find $LIB_DIRS -type f -name '*.so*' -perm /022 -print)
    
    if [ -z "$RECHECK_FILES" ]; then
        echo "✅ Verification Successful: All identified library files have been corrected to be 755 or less permissive."
    else
        echo "❌ Verification Failed: The following files still have incorrect permissions. Manual review is required."
        sudo find $LIB_DIRS -type f -name '*.so*' -perm /022 -exec stat -c "%n - Current Permissions: %a" {} +
    fi
fi

echo "----------------------------------------------------------------"
echo "Script finished."

exit 0
