#!/bin/bash

# ============================================
# CyberJKD Linux Hardening Script
# Author: Dalla Samuel (CyberJKD)
# Phase: Roadmap Phase 1 - Systems Foundation
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Report file
REPORT_FILE="/var/log/cyberjkd_hardening_$(date +%Y%m%d_%H%M%S).log"
REPORT=()

log() {
    local message="$1"
    REPORT+=("$message")
    echo "$message" >> "$REPORT_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run as root: sudo bash harden.sh${NC}"
    exit 1
fi

echo -e "${BLUE}"
echo "============================================"
echo "   CyberJKD Linux Hardening Script"
echo "   Audit. Harden. Verify."
echo "============================================"
echo -e "${NC}"

log "============================================"
log "CyberJKD Linux Hardening Report"
log "Date: $(date)"
log "Hostname: $(hostname)"
log "User: $(whoami)"
log "============================================"

# ---- BASELINE AUDIT ----
echo -e "${CYAN}[*] Running baseline audit before hardening...${NC}"
log ""
log "---- BASELINE AUDIT ----"

BASELINE_PORTS=$(ss -tulnp)
echo -e "${YELLOW}Open ports BEFORE hardening:${NC}"
echo "$BASELINE_PORTS"
log "Open ports before hardening:"
log "$BASELINE_PORTS"

BASELINE_SERVICES=$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null)
log ""
log "Running services before hardening:"
log "$BASELINE_SERVICES"

echo ""

# ---- SECTION 1: DISABLE UNNECESSARY SERVICES ----
echo -e "${YELLOW}[*] Checking and disabling unnecessary services...${NC}"
log ""
log "---- SERVICES ----"

SERVICES=("xrdp" "xrdp-sesman" "lightdm" "rtkit-daemon" "cups" "avahi-daemon" "bluetooth" "ModemManager")

for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        systemctl stop "$service"
        systemctl disable "$service"
        echo -e "${GREEN}[✓] Disabled: $service${NC}"
        log "[DISABLED] $service"
    else
        echo -e "${BLUE}[~] Not running or not installed: $service${NC}"
        log "[SKIPPED] $service - not running or not installed"
    fi
done

# ---- SECTION 2: SSH HARDENING ----
echo -e "${YELLOW}[*] Hardening SSH configuration...${NC}"
log ""
log "---- SSH HARDENING ----"

SSH_CONFIG="/etc/ssh/sshd_config"
cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"
echo -e "${GREEN}[✓] SSH config backed up${NC}"
log "[BACKUP] SSH config backed up to ${SSH_CONFIG}.bak"

declare -A SSH_SETTINGS=(
    ["PermitRootLogin"]="no"
    ["PasswordAuthentication"]="no"
    ["X11Forwarding"]="no"
    ["MaxAuthTries"]="3"
    ["LoginGraceTime"]="30"
    ["AllowAgentForwarding"]="no"
)

for key in "${!SSH_SETTINGS[@]}"; do
    value="${SSH_SETTINGS[$key]}"
    if grep -q "^#*$key" "$SSH_CONFIG"; then
        sed -i "s/^#*$key.*/$key $value/" "$SSH_CONFIG"
        echo -e "${GREEN}[✓] SSH: $key set to $value${NC}"
        log "[SSH] $key set to $value"
    else
        echo "$key $value" >> "$SSH_CONFIG"
        echo -e "${GREEN}[✓] SSH: $key added as $value${NC}"
        log "[SSH] $key added as $value"
    fi
done

systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null
echo -e "${GREEN}[✓] SSH service restarted${NC}"
log "[SSH] Service restarted"

# ---- SECTION 3: FIREWALL ----
echo -e "${YELLOW}[*] Configuring firewall...${NC}"
log ""
log "---- FIREWALL ----"

if ! command -v ufw &>/dev/null; then
    apt install -y ufw &>/dev/null
    log "[UFW] Installed ufw"
fi

ufw --force reset &>/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable
echo -e "${GREEN}[✓] Firewall configured and enabled${NC}"
log "[UFW] Default deny incoming"
log "[UFW] Default allow outgoing"
log "[UFW] SSH allowed on port 22"
log "[UFW] Firewall enabled"

# ---- SECTION 4: FILE PERMISSIONS ----
echo -e "${YELLOW}[*] Hardening file permissions...${NC}"
log ""
log "---- FILE PERMISSIONS ----"

declare -A FILE_PERMS=(
    ["/etc/shadow"]="600"
    ["/etc/passwd"]="644"
    ["/etc/group"]="640"
    ["/etc/gshadow"]="600"
)

for file in "${!FILE_PERMS[@]}"; do
    perm="${FILE_PERMS[$file]}"
    if [ -f "$file" ]; then
        chmod "$perm" "$file"
        echo -e "${GREEN}[✓] $file set to $perm${NC}"
        log "[PERMS] $file set to $perm"
    else
        echo -e "${BLUE}[~] File not found: $file${NC}"
        log "[SKIPPED] $file not found"
    fi
done

# ---- SECTION 5: SECURITY CHECKS ----
echo -e "${YELLOW}[*] Running security checks...${NC}"
log ""
log "---- SECURITY CHECKS ----"

EMPTY_PASS=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null)
if [ -z "$EMPTY_PASS" ]; then
    echo -e "${GREEN}[✓] No accounts with empty passwords${NC}"
    log "[CHECK] Empty passwords: NONE FOUND - PASS"
else
    echo -e "${RED}[!] Accounts with empty passwords: $EMPTY_PASS${NC}"
    log "[CHECK] Empty passwords: FOUND - $EMPTY_PASS - FAIL"
fi

UID0=$(awk -F: '($3 == "0") {print $1}' /etc/passwd)
if [ "$UID0" == "root" ]; then
    echo -e "${GREEN}[✓] Only root has UID 0${NC}"
    log "[CHECK] UID 0 accounts: root only - PASS"
else
    echo -e "${RED}[!] Unauthorized UID 0 accounts: $UID0${NC}"
    log "[CHECK] UID 0 accounts: UNAUTHORIZED FOUND - $UID0 - FAIL"
fi

WORLD_WRITABLE=$(find /etc -type f -perm -o+w 2>/dev/null)
if [ -z "$WORLD_WRITABLE" ]; then
    echo -e "${GREEN}[✓] No world-writable files in /etc${NC}"
    log "[CHECK] World-writable files in /etc: NONE - PASS"
else
    echo -e "${RED}[!] World-writable files found:${NC}"
    echo "$WORLD_WRITABLE"
    log "[CHECK] World-writable files: FOUND - FAIL"
    log "$WORLD_WRITABLE"
fi

# ---- POST HARDENING AUDIT ----
echo ""
echo -e "${CYAN}[*] Running post-hardening audit...${NC}"
log ""
log "---- POST-HARDENING AUDIT ----"

POST_PORTS=$(ss -tulnp)
echo -e "${YELLOW}Open ports AFTER hardening:${NC}"
echo "$POST_PORTS"
log "Open ports after hardening:"
log "$POST_PORTS"

# ---- FINAL REPORT ----
echo -e "${BLUE}"
echo "============================================"
echo "   HARDENING COMPLETE"
echo "   CyberJKD - Becoming dangerous through"
echo "   fundamentals."
echo "============================================"
echo -e "${NC}"
echo -e "${GREEN}[✓] Full report saved to: $REPORT_FILE${NC}"

log ""
log "============================================"
log "HARDENING COMPLETE"
log "Report saved to: $REPORT_FILE"
log "============================================"
