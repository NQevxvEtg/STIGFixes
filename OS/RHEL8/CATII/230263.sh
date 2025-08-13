#!/bin/bash
# V-230263
# ===================================================================================
# STIG Check & Fix for RHEL-08-010350 & associated rules
#
# Rule Title: The RHEL 8 file integrity tool must notify the system administrator
# when changes to the baseline configuration are discovered.
#
# Description:
# This script checks if AIDE is installed and properly configured to run daily
# via cron and send email notifications. If any part of the configuration is
# missing or incorrect, the script will automatically remediate the issue.
#
# Usage:
# 1. Edit the ADMIN_EMAIL variable below.
# 2. Save the script as 'check_aide_stig.sh'.
# 3. chmod +x check_aide_stig.sh
# 4. sudo ./check_aide_stig.sh
# ===================================================================================

# --- Script Configuration ---
# MODIFICATION REQUIRED:
# Replace the email addresses below with a comma-separated list of recipients.
ADMIN_EMAIL="admin1@example.com,security.team@example.com"

# --- Script Variables ---
CRON_SCRIPT="/etc/cron.daily/aide"
AIDE_DB="/var/lib/aide/aide.db"

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

# --- Root Check ---
if [[ "$EUID" -ne 0 ]]; then
  log_error "This script must be run as root or with sudo."
  exit 1
fi

log_info "Starting AIDE configuration check for STIG RHEL-08-010350..."
COMPLIANT=true

# --- Step 1: Check for required packages ---
log_info "Checking for 'aide' and 'mailx' packages..."
PACKAGES_MISSING=false
for pkg in aide mailx; do
  if ! rpm -q "$pkg" &>/dev/null; then
    log_warn "Package '$pkg' is not installed."
    PACKAGES_MISSING=true
    COMPLIANT=false
  fi
done

if [ "$PACKAGES_MISSING" = true ]; then
  log_info "Attempting to install missing packages..."
  if dnf install -y aide mailx &>/dev/null; then
    log_ok "Successfully installed required packages."
  else
    log_error "Failed to install required packages. Please install 'aide' and 'mailx' manually."
    exit 1
  fi
else
  log_ok "'aide' and 'mailx' packages are already installed."
fi


# --- Step 2: Check for AIDE database ---
log_info "Checking for AIDE database at $AIDE_DB..."
if [ ! -f "$AIDE_DB" ]; then
  log_warn "AIDE database does not exist. Initializing a new baseline."
  COMPLIANT=false
  log_info "Running 'aide --init'. This may take a several minutes..."
  
  if aide --init &>/dev/null; then
    log_info "AIDE initialization complete. Moving new database into place."
    mv /var/lib/aide/aide.db.new "$AIDE_DB"
    log_ok "Successfully created and installed new AIDE database."
  else
    log_error "AIDE database initialization failed. Please run 'aide --init' manually to debug."
    exit 1
  fi
else
  log_ok "AIDE database already exists."
fi

# --- Step 3: Check and remediate the cron job ---
log_info "Checking for cron job at $CRON_SCRIPT..."

# Define the desired content for the cron script
# We escape \$HOSTNAME so it's evaluated by cron, not by this script.
read -r -d '' DESIRED_CONTENT <<EOF
#!/bin/bash
#
# This script runs the AIDE integrity check and emails the report.
# This file is managed by an automated compliance script.
#

ADMIN_EMAIL="${ADMIN_EMAIL}"

/usr/sbin/aide --check | /bin/mail -s "[\$HOSTNAME] Daily AIDE Integrity Check Report" "\$ADMIN_EMAIL"
EOF

# Check if the cron file exists and has the correct content
NEEDS_FIX=false
if [ ! -f "$CRON_SCRIPT" ]; then
  log_warn "Cron script does not exist."
  NEEDS_FIX=true
  COMPLIANT=false
# Use diff to compare the actual content with the desired content
elif ! diff -q <(echo -n "$DESIRED_CONTENT") "$CRON_SCRIPT" &>/dev/null; then
  log_warn "Cron script has incorrect content."
  NEEDS_FIX=true
  COMPLIANT=false
fi

if [ "$NEEDS_FIX" = true ]; then
  log_info "Creating/overwriting cron script with compliant content..."
  echo -n "$DESIRED_CONTENT" > "$CRON_SCRIPT"
  if [ $? -eq 0 ]; then
    log_ok "Successfully wrote new cron script."
  else
    log_error "Failed to write to $CRON_SCRIPT."
    exit 1
  fi
fi

# Check if the cron file is executable
if [ ! -x "$CRON_SCRIPT" ]; then
  log_warn "Cron script is not executable."
  COMPLIANT=false
  log_info "Setting executable permissions on $CRON_SCRIPT..."
  chmod 755 "$CRON_SCRIPT"
  log_ok "Permissions set to 755."
fi

if [ "$COMPLIANT" = true ]; then
  log_ok "Cron job configuration is compliant."
else
  # This message shows if a fix was applied. We re-verify for the final status.
  log_ok "All identified issues have been remediated."
fi

# --- Final Status ---
echo ""
log_ok "System is now configured for daily AIDE checks and notifications."
log_info "To test the email functionality, run: sudo $CRON_SCRIPT"
exit 0