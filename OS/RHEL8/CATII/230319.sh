#!/bin/bash
# V-230319
# ===================================================================================
# STIG Check & Fix for RHEL-08-010341
#
# Rule Title: All RHEL 8 world-writable directories must be group-owned by root,
# sys, bin, or an application group.
#
# Description:
# This script scans all local filesystems for world-writable directories that are
# group-owned by non-system groups (GID >= 1000). It remediates findings by
# changing the group ownership of these directories to 'root'.
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
# Use findmnt to get a list of local, standard filesystem types (ignores NFS, etc.).
LOCAL_MOUNTS=$(findmnt -l -n -t xfs,ext4,btrfs -o TARGET)

if [ -z "$LOCAL_MOUNTS" ]; then
  log_error "Could not identify any local filesystems to scan. Aborting."
  exit 1
fi

log_info "Will scan the following filesystems: ${LOCAL_MOUNTS}"
echo "-----------------------------------------------------"

# --- 2. Find and fix non-compliant directories ---
# -xdev prevents crossing into other filesystems.
# -perm -0002 finds directories with the world-writable bit set.
# -gid +999 finds files group-owned by GID 1000 or higher.
NON_COMPLIANT_DIRS=$(find ${LOCAL_MOUNTS} -xdev -type d -perm -0002 -gid +999)

if [ -z "$NON_COMPLIANT_DIRS" ]; then
    log_ok "Scan complete. No non-compliant world-writable directories found. ✅"
    exit 0
fi

log_warn "Found world-writable directories not group-owned by a system account. Applying fixes..."
MODIFICATIONS_MADE=false

while IFS= read -r dir; do
    log_info "Changing group ownership of '${dir}' to root..."
    if chgrp root "${dir}"; then
        log_ok "Successfully changed group for '${dir}'."
        MODIFICATIONS_MADE=true
    else
        log_error "Failed to change group for '${dir}'."
    fi
done <<< "$NON_COMPLIANT_DIRS"

echo "-----------------------------------------------------"

if [ "$MODIFICATIONS_MADE" = true ]; then
    log_ok "Scan and remediation complete. All found directories now group-owned by root. ✅"
else
    log_error "Scan complete, but failed to remediate all findings. Manual review needed."
fi

exit 0