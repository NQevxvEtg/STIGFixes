#!/bin/bash
# V-230311
# ===================================================================================
# STIG Check & Fix for RHEL-08-010131
#
# Rule Title: RHEL 8 must disable the kernel.core_pattern.
#
# Description:
# This script ensures that core dump generation is disabled by setting the
# 'kernel.core_pattern' sysctl parameter to '|/bin/false'. It establishes a
# high-precedence configuration file and comments out any conflicting entries
# in other sysctl configuration files.
# ===================================================================================

# --- Configuration ---
PARAM_NAME="kernel.core_pattern"
PARAM_VALUE="|/bin/false"
# Use a file with a high number (e.g., 99) to ensure it's processed last.
CONFIG_FILE="/etc/sysctl.d/99-disable-core-dumps.conf"

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

log_info "Starting remediation for disabling kernel core dumps..."
MODIFICATIONS_MADE=false

# --- 1. Create the authoritative configuration file ---
log_info "Ensuring the master configuration file is present and correct..."
if ! grep -q -F "${PARAM_NAME} = ${PARAM_VALUE}" "${CONFIG_FILE}" 2>/dev/null; then
    echo "${PARAM_NAME} = ${PARAM_VALUE}" > "${CONFIG_FILE}"
    chmod 644 "${CONFIG_FILE}"
    log_ok "Created/corrected master config file at ${CONFIG_FILE}."
    MODIFICATIONS_MADE=true
else
    log_ok "Master config file is already correct."
fi
echo "-----------------------------------------------------"

# --- 2. Find and neutralize conflicting configurations ---
log_info "Searching for conflicting settings in other sysctl files..."
CONFLICT_FILES=$(grep -rsl --exclude="$(basename ${CONFIG_FILE})" "^[[:space:]]*${PARAM_NAME}" /etc/sysctl.conf /etc/sysctl.d/ /usr/lib/sysctl.d/ /run/sysctl.d/)

if [ -z "$CONFLICT_FILES" ]; then
    log_ok "No conflicting configurations found."
else
    log_warn "Found conflicting settings. Neutralizing them..."
    for file in $CONFLICT_FILES; do
        # Comment out the conflicting line and add a note
        sed -i -E "s/^[[:space:]]*(${PARAM_NAME}.*)/# \1 # Neutralized by compliance script/g" "$file"
        log_info "Commented out entry in: $file"
        MODIFICATIONS_MADE=true
    done
    log_ok "All conflicting settings have been neutralized."
fi
echo "-----------------------------------------------------"

# --- 3. Reload sysctl settings if changes were made ---
if [ "$MODIFICATIONS_MADE" = true ]; then
    log_info "Applying changes to the running kernel..."
    if sysctl --system &>/dev/null; then
        log_ok "Sysctl settings successfully reloaded."
    else
        log_error "Failed to reload sysctl settings. Please run 'sysctl --system' manually."
        exit 1
    fi
else
    log_info "No configuration changes were needed."
fi
echo "-----------------------------------------------------"

# --- 4. Final verification ---
log_info "Verifying active kernel setting..."
ACTIVE_VALUE=$(sysctl -n "${PARAM_NAME}")

if [[ "${ACTIVE_VALUE}" == "${PARAM_VALUE}" ]]; then
    log_ok "Kernel parameter '${PARAM_NAME}' is correctly set to '${PARAM_VALUE}'. ✅"
else
    log_error "Verification FAILED. Active value is '${ACTIVE_VALUE}'. Manual review required."
    exit 1
fi

exit 0