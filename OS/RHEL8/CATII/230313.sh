#!/bin/bash
# V-230313
# ===================================================================================
# STIG Check & Fix for RHEL-08-010150 (Corrected Version)
#
# Rule Title: RHEL 8 must disable core dumps for all users.
#
# Description:
# This script ensures that core dumps are disabled for all users by setting
# a hard limit of 0. It creates a high-precedence configuration file in
# /etc/security/limits.d/ and comments out any other conflicting 'core'
# limit definitions.
# ===================================================================================

# --- Configuration ---
DESIRED_SETTING="* hard core 0"
# Use a file with a high number to ensure it's processed last.
CONFIG_FILE="/etc/security/limits.d/99-disable-core-dumps.conf"

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

log_info "Starting remediation for disabling user core dumps..."
MODIFICATIONS_MADE=false

# --- 1. Create the authoritative configuration file ---
log_info "Ensuring the master configuration file is present and correct..."

# **FIX:** Ensure the target directory exists before trying to write to it.
# The '-p' flag prevents errors if the directory already exists.
mkdir -p "$(dirname "${CONFIG_FILE}")"

if ! grep -q -F "${DESIRED_SETTING}" "${CONFIG_FILE}" 2>/dev/null; then
    echo "# This file is managed by a compliance script to disable core dumps for all users." > "${CONFIG_FILE}"
    echo "${DESIRED_SETTING}" >> "${CONFIG_FILE}"
    chmod 644 "${CONFIG_FILE}"
    log_ok "Created/corrected master config file at ${CONFIG_FILE}."
    MODIFICATIONS_MADE=true
else
    log_ok "Master config file is already correct."
fi
echo "-----------------------------------------------------"

# --- 2. Find and neutralize conflicting configurations ---
log_info "Searching for conflicting 'core' settings in other limits files..."
# Find any uncommented line containing 'core' in the 3rd field.
CONFLICT_FILES=$(grep -rsl --exclude="$(basename ${CONFIG_FILE})" -E '^[[:space:]]*[^#]+[[:space:]]+(hard|soft|-)[[:space:]]+core' /etc/security/limits.conf /etc/security/limits.d/ 2>/dev/null)

if [ -z "$CONFLICT_FILES" ]; then
    log_ok "No conflicting configurations found."
else
    log_warn "Found conflicting settings. Neutralizing them..."
    for file in $CONFLICT_FILES; do
        # Comment out the conflicting line and add a note
        sed -i -E "s/^[[:space:]]*([^#]+[[:space:]]+(hard|soft|-)[[:space:]]+core.*)/# \1 # Neutralized by compliance script/g" "$file"
        log_info "Commented out conflicting entry in: $file"
        MODIFICATIONS_MADE=true
    done
    log_ok "All conflicting settings have been neutralized."
fi
echo "-----------------------------------------------------"

# --- 3. Final Status ---
if [ "$MODIFICATIONS_MADE" = true ]; then
    log_ok "System configuration has been updated."
else
    log_ok "System was already compliant. No changes were needed."
fi

log_info "The 'hard core 0' limit is now correctly configured. ✅"
log_warn "Note: This change will apply to all new user login sessions."

exit 0