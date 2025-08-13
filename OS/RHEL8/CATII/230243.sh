#!/bin/bash
# V-230243
# Check & fix world-writable mount-points that are missing the sticky bit
df --output=target | tail -n +2 | while read -r mnt
do
    printf "Checking %-50s ... " "$mnt"
    if [ -d "$mnt" ]; then
        perm=$(stat -c '%a' "$mnt")
        sticky=$(stat -c '%A' "$mnt" | cut -b10)
        if [[ "$perm" -eq 777 ]] && [[ "$sticky" != "t" ]]; then
            sudo chmod +t "$mnt"
            printf "FIXED (sticky bit added)\n"
        else
            printf "OK\n"
        fi
    else
        printf "SKIPPED (not a dir)\n"
    fi
done
