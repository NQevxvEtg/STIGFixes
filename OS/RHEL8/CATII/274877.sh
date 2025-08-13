#!/bin/bash

# ===================================================================================
# STIG Check & Fix for RHEL-08-030140 (Corrected Version)
#
# Rule Title: RHEL 8 must audit any script or executable called by cron as
# root or by any privileged user.
#
# Description:
# This script ensures that auditd is configured to monitor for write and
# attribute change access to the system's cron directories.
# ===================================================================================

# --- Configuration ---
CONFIG_FILE="/etc/audit/rules.d/99-cron-auditing.rules"
RULE1="-w /etc/cron.d/ -p wa -k cronjobs"
RULE2="-w /var/spool/cron/ -p wa -k cronjobs"

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

log_info "Starting remediation for cron auditing rules..."
MODIFICATIONS_MADE=false

# --- 1. Check if the configuration file needs to be created or updated ---
# **FIX:** Added '-e' to grep to handle patterns that start with a dash.
if [ ! -f "$CONFIG_FILE" ] || ! grep -q -F -e "$RULE1" "$CONFIG_FILE" || ! grep -q -F -e "$RULE2" "$CONFIG_FILE"; then
    log_warn "Audit rule file is missing or incorrect. Creating/overwriting..."
    
    (
    echo "# STIG ID: RHEL-08-030140"
    echo "$RULE1"
    echo "$RULE2"
    ) > "$CONFIG_FILE"

    if [ $? -eq 0 ]; then
        chmod 640 "$CONFIG_FILE"
        log_ok "Successfully created audit rule file at ${CONFIG_FILE}."
        MODIFICATIONS_MADE=true
    else
        log_error "Failed to write to ${CONFIG_FILE}. Aborting."
        exit 1
    fi
else
    log_ok "Audit rule file is already correct."
fi
echo "-----------------------------------------------------"

# --- 2. Reload audit rules if changes were made ---
if [ "$MODIFICATIONS_MADE" = true ]; then
    log_info "Applying new audit rules to the running kernel..."
    # **FIX:** Removed output redirection to show error messages from augenrules.
    if augenrules --load; then
        log_ok "Audit rules successfully reloaded."
    else
        log_error "Failed to reload audit rules. Check the output above for errors."
        log_warn "Common causes include the 'auditd' service not running. Try 'systemctl start auditd'."
        exit 1
    fi
else
    log_info "No configuration changes were needed."
fi
echo "-----------------------------------------------------"

# --- 3. Final verification ---
log_info "Verifying active audit rules..."
if auditctl -l | grep -q -- "-w /etc/cron.d -p wa -k cronjobs" && auditctl -l | grep -q -- "-w /var/spool/cron -p wa -k cronjobs"; then
    log_ok "Cron auditing rules are active in the current kernel configuration. ✅"
else
    log_error "Verification FAILED. One or more cron audit rules are not active. Manual review required."
    exit 1
fi

exit 0