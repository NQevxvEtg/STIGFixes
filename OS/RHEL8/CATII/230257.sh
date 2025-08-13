#!/bin/bash
# V-230257
# Fix Script for Rule: RHEL 8 system commands must have mode 755 or less permissive.
#
# Description:
# This script scans standard system command directories for files with permissions
# more permissive than 755 (i.e., group-writable or world-writable).
# It correctly handles symbolic links by modifying the permissions of the target file.
# It then corrects the permissions to 755 and logs the changes.
#
# This script should be run with root privileges (e.g., using sudo).
#

# Define the directories to scan as per the security guidance
DIRECTORIES_TO_CHECK="/bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin"

echo "### Starting Scan: System Command Permissions ###"
echo "Searching for files with permissions more permissive than 755 in:"
echo "$DIRECTORIES_TO_CHECK"
echo "----------------------------------------------------------------------"

# Use find to locate files (-type f) that are group-writable or world-writable (-perm /022).
# The -L option ensures that we follow symbolic links to check the permissions of the target file.
# Using -print0 and read -d '' is a robust way to handle filenames with spaces or special characters.
find -L $DIRECTORIES_TO_CHECK -type f -perm /022 -print0 | while IFS= read -r -d $'\0' FILE_FOUND; do
    # Get the canonical path, which resolves any symbolic links.
    # This ensures we operate on the actual file, not the link.
    REAL_FILE=$(readlink -f "$FILE_FOUND")

    # Double-check that the path exists and is a file before proceeding.
    if [ -f "$REAL_FILE" ]; then
        echo "FIXING: Found item with insecure permissions: $FILE_FOUND"

        # Show the state before the fix
        echo "  [BEFORE] Details for link/file:"
        ls -ld "$FILE_FOUND"
        # If the found item was a link, show the target's permissions too for clarity
        if [ "$FILE_FOUND" != "$REAL_FILE" ]; then
            echo "  [BEFORE] Details for target file:"
            ls -l "$REAL_FILE"
        fi

        # Apply the fix to the actual file (the target of the link)
        chmod 755 "$REAL_FILE"

        # Show the state after the fix to confirm the change
        echo "  [AFTER] Details for link/file:"
        ls -ld "$FILE_FOUND"
        if [ "$FILE_FOUND" != "$REAL_FILE" ]; then
            echo "  [AFTER] Details for target file:"
            ls -l "$REAL_FILE"
        fi
        echo "----------------------------------------------------------------------"
    fi
done

echo "### Scan and Fix Complete ###"
