# CyberJKD Linux Hardening Script

**Author:** Dalla  Samuel (CyberJKD)  
**Phase:** Roadmap Phase 1 — Systems Foundation  
**Language:** Bash  

---

## Overview

An automated Linux hardening script that audits, hardens, and verifies the security state of a Debian-based Linux system. Built as part of the CyberJKD cybersecurity learning roadmap.

The script follows a simple principle — **audit first, harden second, verify third.**

---

## What It Does

- Baseline port audit before any changes
- Disables unnecessary services (xrdp, lightdm, cups, avahi-daemon, bluetooth)
- Hardens SSH configuration with secure defaults
- Configures ufw firewall with default deny incoming policy
- Sets correct permissions on sensitive system files
- Runs security checks for empty passwords, unauthorized UID 0 accounts, and world-writable files
- Post-hardening port audit to confirm attack surface reduction
- Saves a full timestamped report to `/var/log/`

---

## Usage
```bash
sudo bash harden.sh
```

Run as root. The script handles everything automatically.

---

## Sample Output
```
============================================
   CyberJKD Linux Hardening Script
   Audit. Harden. Verify.
============================================
[*] Running baseline audit before hardening...
[*] Checking and disabling unnecessary services...
[✓] Disabled: rtkit-daemon
[~] Not running or not installed: xrdp
[*] Hardening SSH configuration...
[✓] SSH config backed up
[✓] SSH: PermitRootLogin set to no
[✓] SSH: PasswordAuthentication set to no
[✓] SSH: MaxAuthTries set to 3
[✓] SSH service restarted
[*] Configuring firewall...
[✓] Firewall configured and enabled
[*] Hardening file permissions...
[✓] /etc/shadow set to 600
[✓] /etc/passwd set to 644
[*] Running security checks...
[✓] No accounts with empty passwords
[✓] Only root has UID 0
[✓] No world-writable files in /etc
[*] Running post-hardening audit...
============================================
   HARDENING COMPLETE
   CyberJKD - Becoming dangerous through
   fundamentals.
============================================
[✓] Full report saved to: /var/log/cyberjkd_hardening_20260323_000903.log
```

---

## Report

After each run a full timestamped report is saved to:
```
/var/log/cyberjkd_hardening_YYYYMMDD_HHMMSS.log
```

The report includes:
- Baseline services and open ports before hardening
- Every action taken with pass or fail status
- Security check results
- Post-hardening port state

---

## Compatibility

Tested on: Kali Linux (WSL2)  
Should work on any Debian-based Linux system.

---

## Part of the CyberJKD Roadmap

This script is Phase 1 of the CyberJKD cybersecurity learning roadmap — building strong foundations before advancing to offensive security and cloud engineering.

Check out the full roadmap: [github.com/DallaSamuel](https://github.com/DallaSamuel/CyberJKD-Roadmap)

---

*CyberJKD — Becoming dangerous through fundamentals. 🔒*
