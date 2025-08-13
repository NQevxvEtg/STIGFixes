#!/bin/bash
# V-230259
# Fix Script for Rule: RHEL 8 system commands must be group-owned by root or a system account.
#
# Description:
# This script scans standard system command directories for any files or links
# pointing to files that are not group-owned by 'root'.
# While the rule allows for other system accounts, this script standardizes
# the group-ownership to 'root' as per the common fix text.
# It correctly handles symbolic links by changing the group of the target file.
#
# This script should be run with root privileges (e.g., using sudo).
#

# Define the directories to scan as per the security guidance
DIRECTORIES_TO_CHECK="/bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin"

echo "### Starting Scan: System Command Group-Ownership ###"
echo "Searching for files not group-owned by 'root' in:"
echo "$DIRECTORIES_TO_CHECK"
echo "----------------------------------------------------------------------"

# Use find to locate files that are not group-owned by 'root'.
# The -L option ensures that we follow symbolic links to check the group of the target file.
# Using -print0 and read -d '' is a robust way to handle filenames with spaces or special characters.
find -L $DIRECTORIES_TO_CHECK ! -group root -print0 | while IFS= read -r -d $'\0' FILE_FOUND; do
    # Get the canonical path, which resolves any symbolic links.
    # This ensures we operate on the actual file, not the link.
    REAL_FILE=$(readlink -f "$FILE_FOUND")

    # Double-check that the real file path exists before proceeding.
    if [ -e "$REAL_FILE" ]; then
        echo "FIXING: Found item not group-owned by root: $FILE_FOUND"

        # Show the state before the fix
        echo "  [BEFORE] Details for link/file:"
        ls -ld "$FILE_FOUND"
        # If the found item was a link, show the target's details too for clarity
        if [ "$FILE_FOUND" != "$REAL_FILE" ]; then
            echo "  [BEFORE] Details for target file:"
            ls -l "$REAL_FILE"
        fi

        # Apply the fix to the actual file (the target of the link)
        chgrp root "$REAL_FILE"

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
