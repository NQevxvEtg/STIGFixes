#!/bin/bash
# V-230327
# ===================================================================================
# STIG Check & Fix for RHEL-08-010331
#
# Rule Title: All RHEL 8 local files and directories must have a valid group owner.
#
# Description:
# This script scans all local filesystems for files and directories that do not
# have a valid group ('nogroup'). It remediates findings by changing the
# group ownership of these files to 'root'.
# ===================================================================================

# --- Color Codes for Output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Helper Functions for Logging ---
log_info() { echo -e "[INFO] $1"; }
log_ok() { echo -e "${GREEN}[OK]   $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# --- Ensure script is run as root ---
if [[ "$EUID" -ne 0 ]]; then
  log_error "This script must be run as root or with sudo."
  exit 1
fi

# --- 1. Identify local filesystems ---
log_info "Identifying local filesystems to scan..."
# df --local lists only local filesystems. -P ensures POSIX-compliant output.
# awk prints the 6th column (mount point), skipping the header.
LOCAL_MOUNTS=$(df --local -P | awk 'NR!=1 {print $6}')

if [ -z "$LOCAL_MOUNTS" ]; then
  log_error "Could not identify any local filesystems to scan. Aborting."
  exit 1
fi

log_info "Will scan the following filesystems: ${LOCAL_MOUNTS}"
echo "-----------------------------------------------------"

# --- 2. Find and fix files without a valid group ---
log_info "Searching for files and directories without a valid group owner..."
UNGROUPED_FILES=$(find ${LOCAL_MOUNTS} -xdev -nogroup -print)

if [ -z "$UNGROUPED_FILES" ]; then
    log_ok "Scan complete. No files or directories without a valid group found. ✅"
    exit 0
fi

log_warn "Found files/directories without a valid group. Applying fixes..."
MODIFICATIONS_MADE=false

# Use a while loop for better logging of each file changed
while IFS= read -r file; do
    log_info "Changing group of '${file}' to root..."
    if chgrp root "${file}"; then
        log_ok "Successfully changed group for '${file}'."
        MODIFICATIONS_MADE=true
    else
        log_error "Failed to change group for '${file}'."
    fi
done <<< "$UNGROUPED_FILES"

echo "-----------------------------------------------------"

if [ "$MODIFICATIONS_MADE" = true ]; then
    log_ok "Scan and remediation complete. All found files now have the 'root' group. ✅"
else
    log_error "Scan complete, but failed to remediate all findings. Manual review needed."
fi

exit 0