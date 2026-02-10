# OpenClaw Windows 10 Security Hardening Scripts

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue.svg)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-purple.svg)](https://docs.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

## Overview

This project provides a complete set of Windows 10/11 security hardening scripts for securely deploying OpenClaw AI Gateway in enterprise environments. The scripts follow CIS Windows Security Benchmark and Microsoft security best practices for automated security configuration.

**Features**: **Interactive multi-select interface** allowing users to freely choose which hardening items to execute!

## Author Information

| Item | Information |
|------|-------------|
| **Author** | Alex |
| **Email** | unix_sec@163.com |
| **Version** | 1.3.0 |
| **Created** | 2026-02-05 |
| **Updated** | 2026-02-10 |

## v1.3 New Features

| Feature | Description |
|---------|-------------|
| **One-click Rollback** | Rollback all/pre-deployment/post-deployment hardening items in reverse order |
| **Phase-based Rollback** | New menu options `[R] Rollback pre-deployment` and `[T] Rollback post-deployment` |
| **Execution Report** | Detailed report after every batch apply/rollback (success/skipped/failed statistics) |
| **CLI Batch Rollback** | New `--rollback-all`, `--rollback-pre`, `--rollback-post` CLI arguments |
| **CLI Report Output** | Report summary also output for `--apply`/`--pre`/`--post`/`--rollback` CLI usage |
| **Result Tracking** | `apply_item`/`rollback_item` automatically track results (success/skipped/failed) |

## Features

### Core Features

- ✅ **Service Account Management** - Create dedicated service account with minimal privileges
- ✅ **File Permission Hardening** - NTFS ACL configuration, remove unnecessary access permissions
- ✅ **Firewall Configuration** - Windows Firewall rules to block unauthorized access
- ✅ **Defender Configuration** - Windows Defender real-time protection and ASR rules
- ✅ **Audit Policy** - Security event auditing with SIEM integration support
- ✅ **Secure Config Generation** - Auto-generate secure configuration files and tokens
- ✅ **Security Audit Report** - One-click security status check
- ✅ **Emergency Rollback** - Quick restore to default configuration

### Security Hardening Items

| Item | Description | Severity |
|------|-------------|----------|
| Service Account Isolation | Run service with dedicated low-privilege account | High |
| Config File Permissions | Remove Everyone/Users access to sensitive files | High |
| Network Isolation | Gateway binds to loopback address only | High |
| Firewall Rules | Block external access to Gateway port | High |
| Real-time Protection | Enable Windows Defender real-time scanning | Medium |
| Behavior Monitoring | Enable suspicious behavior detection | Medium |
| ASR Rules | Attack Surface Reduction rules | Medium |
| Security Auditing | Enable logon, process, file access auditing | Medium |

## System Requirements

### Minimum Requirements

- **OS**: Windows 10 version 1809+ / Windows 11 / Windows Server 2016+
- **PowerShell**: 5.1 or higher
- **Privileges**: Administrator
- **Disk Space**: 100 MB (for logs and configuration)

### Recommended Environment

- Windows 10 Enterprise / Windows 11 Enterprise
- PowerShell 7.x
- Windows Defender (not third-party antivirus)
- Domain environment (for Group Policy integration)


## Quick Start

### Method 1: Using BAT Script (Recommended for Beginners)

1. Right-click `windows-security-hardening.bat`
2. Select **"Run as administrator"**
3. Choose operation mode from main menu:
   - `[1]` **Interactive Selection** - Freely choose hardening items (recommended)
   - `[2]` One-click Full Hardening - Execute all hardening items
4. If choosing interactive mode:
   - Enter `1-7` to select/deselect hardening items
   - Enter `A` to select all
   - Enter `E` to execute
5. Follow the prompts to complete configuration

### Method 2: Using PowerShell Script

```powershell
# 1. Open PowerShell as Administrator

# 2. Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Navigate to script directory
cd "C:\path\to\scripts"

# 4. Execute full security hardening
.\windows-security-hardening.ps1 -Action All
```

## Detailed Usage

### BAT Script - Main Menu

| Option | Function | Description |
|--------|----------|-------------|
| 1 | **Interactive Selection** | Enter multi-select interface to freely choose hardening items (recommended) |
| 2 | One-click Full Hardening | Execute all hardening items at once |
| 3 | Security Audit Report | Check current security configuration status |
| 4 | Rollback Hardening | Emergency restore to default configuration |
| 0 | Exit | Exit the script |

### BAT Script - Interactive Selection Interface

After entering interactive selection, use the following operations:

| Operation | Description |
|-----------|-------------|
| `1-7` | Toggle selection state of corresponding item (enter again to deselect) |
| `123` | Toggle multiple items simultaneously (supports consecutive digit input) |
| `A` | **Select all** hardening items |
| `N` | Deselect all |
| `E` | Execute selected hardening items |
| `B` | Return to main menu |

### Available Hardening Items

| # | Item | Description |
|---|------|-------------|
| 1 | Create Service Account | Create low-privilege openclaw_svc account |
| 2 | Configure File Permissions | Configure NTFS ACL permissions |
| 3 | Configure Firewall | Configure Windows Firewall rules |
| 4 | Configure Windows Defender | Enable protection features and ASR rules |
| 5 | Enable Audit Policy | Configure security event auditing |
| 6 | Generate Secure Config | Generate secure configuration files and Token |
| 7 | Install Service | Install Windows service using NSSM |

### PowerShell Script Parameters

```powershell
.\windows-security-hardening.ps1
    [-Action <String>]          # Action to perform
    [-ServiceAccount <String>]  # Service account name (default: openclaw_svc)
    [-GatewayPort <Int>]        # Gateway port (default: 18789)
    [-OpenClawDir <String>]     # OpenClaw installation directory (default: C:\OpenClaw)
    [-Force]                    # Force execution, skip confirmation
    [-WhatIf]                   # Preview mode, no actual execution
```

#### Action Parameter Values

| Value | Description |
|-------|-------------|
| `All` | Execute full security hardening (default) |
| `Account` | Create service account only |
| `Permissions` | Configure file permissions only |
| `Firewall` | Configure firewall only |
| `Defender` | Configure Windows Defender only |
| `Audit` | Enable audit policy only |
| `Service` | Install service (requires NSSM) |
| `Report` | Generate security audit report |
| `Rollback` | Rollback security hardening |

### BAT Script Usage Example

```
========================================
Interactive Selection Interface Example
========================================

[ ] [1] Create Service Account
[√] [2] Configure File Permissions    <- Selected
[√] [3] Configure Firewall            <- Selected
[ ] [4] Configure Windows Defender
[ ] [5] Enable Audit Policy
[√] [6] Generate Secure Config        <- Selected
[ ] [7] Install Service

Enter option: 236     <- Enter 236 to toggle these three items
Enter option: A       <- Enter A to select all
Enter option: E       <- Enter E to execute selected items
```

### PowerShell Script Usage Examples

```powershell
# Example 1: Full security hardening
.\windows-security-hardening.ps1 -Action All

# Example 2: Preview mode (no actual execution)
.\windows-security-hardening.ps1 -Action All -WhatIf

# Example 3: Custom service account and port
.\windows-security-hardening.ps1 -Action All -ServiceAccount "my_openclaw" -GatewayPort 8080

# Example 4: Generate security audit report only
.\windows-security-hardening.ps1 -Action Report

# Example 5: Force rollback (skip confirmation)
.\windows-security-hardening.ps1 -Action Rollback -Force
```

## Configuration

### Default Configuration

The script uses the following default configuration, which can be modified as needed:

```powershell
$Config = @{
    OpenClawDir    = "C:\OpenClaw"                # OpenClaw installation directory
    StateDir       = "$env:USERPROFILE\.openclaw" # State directory
    LogsDir        = "C:\Logs\OpenClaw"           # Logs directory
    SecretsDir     = "C:\OpenClaw\secrets"        # Secrets directory
    ServiceAccount = "openclaw_svc"               # Service account
    GatewayPort    = 18789                        # Gateway port
}
```

### Directory Permission Configuration

| Directory | Permission Configuration |
|-----------|-------------------------|
| `C:\OpenClaw` | SYSTEM: Full Control, Administrators: Full Control, openclaw_svc: Read & Execute |
| `%USERPROFILE%\.openclaw` | SYSTEM: Full Control, Administrators: Full Control, openclaw_svc: Modify, Current User: Full Control |
| `C:\OpenClaw\secrets` | SYSTEM: Full Control, Administrators: Full Control, openclaw_svc: Read Only |
| `C:\Logs\OpenClaw` | SYSTEM: Full Control, Administrators: Full Control, openclaw_svc: Modify |

## Security Audit Report

Running the security audit report checks the following items:

| Check Item | Expected Result |
|------------|-----------------|
| Service account exists | ✅ PASS |
| Service account not in Administrators group | ✅ PASS |
| Config file permissions correct | ✅ PASS |
| Firewall enabled | ✅ PASS |
| Firewall rules configured | ✅ PASS |
| Gateway port not exposed externally | ✅ PASS |
| Windows Defender running | ✅ PASS |
| Real-time protection enabled | ✅ PASS |
| Service not running as LocalSystem | ✅ PASS |

### Sample Report Output

```
========================================
OpenClaw Windows Security Audit Report
========================================
Date: 2026-02-05 14:30:00

[1] Checking service account...
  [PASS] Service account exists
  [PASS] Service account not in Administrators group

[2] Checking file permissions...
  [PASS] config.yaml permissions configured correctly

[3] Checking firewall...
  [PASS] Windows Firewall enabled
  [PASS] OpenClaw firewall rules configured

[4] Checking port exposure...
  [PASS] Gateway port not exposed externally

[5] Checking Windows Defender...
  [PASS] Real-time protection enabled
  [PASS] Behavior monitoring enabled

[6] Checking service...
  [INFO] Service status: Running
  [PASS] Service account: .\openclaw_svc

========================================
Audit Summary
========================================
No critical security issues found
```

## Post-Hardening Steps

1. **Change service account password**
   ```batch
   net user openclaw_svc *
   ```

2. **View generated Gateway Token**
   ```batch
   type C:\OpenClaw\secrets\gateway-token.txt
   ```

3. **Start OpenClaw service** (if installed)
   ```batch
   net start OpenClawGateway
   ```

4. **Run security audit regularly**
   ```powershell
   .\windows-security-hardening.ps1 -Action Report
   ```

5. **Configure scheduled task for regular auditing**
   ```powershell
   # Create daily security audit task
   $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
       -Argument "-File C:\OpenClaw\scripts\windows-security-hardening.ps1 -Action Report"
   $Trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
   Register-ScheduledTask -TaskName "OpenClaw Security Audit" -Action $Action -Trigger $Trigger
   ```

## Troubleshooting

### Common Issues

#### Q1: Script shows "Please run as administrator"

**Solution**: Right-click the script and select "Run as administrator"

#### Q2: PowerShell execution policy blocks script

**Solution**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Q3: Service account creation failed

**Solution**: Check if an account with the same name exists, or use a different account name:
```powershell
.\windows-security-hardening.ps1 -Action Account -ServiceAccount "my_openclaw_svc"
```

#### Q4: Firewall rule configuration failed

**Solution**: Ensure Windows Firewall service is running:
```powershell
Get-Service -Name MpsSvc | Start-Service
```

#### Q5: How to completely rollback hardening configuration?

**Solution**:
```powershell
.\windows-security-hardening.ps1 -Action Rollback -Force
```

### Log Location

All operation logs are saved to:
```
%TEMP%\openclaw-hardening-YYYYMMDD-HHmmss.log
```

## Security Recommendations

1. **Regular Updates** - Keep Windows and scripts updated to latest versions
2. **Least Privilege** - Do not add service account to Administrators group
3. **Password Security** - Use strong passwords and rotate regularly
4. **Log Monitoring** - Regularly check security logs and audit reports
5. **Backup Configuration** - Backup existing configuration before hardening
6. **Test Environment** - Validate scripts in test environment first

## Changelog

### v1.3.0 (2026-02-10)
- Added: One-click rollback for all/pre-deployment/post-deployment hardening items
- Added: Execution report summary after every batch operation (success/skipped/failed details)
- Added: `:rollback_phase` for phase-based rollback in reverse order
- Added: `:reset_report`/`:print_report`/`:report_ok`/`:report_skip`/`:report_fail` report functions
- Added: `:cli_rollback` for CLI batch rollback
- Added: CLI arguments `--rollback-all`, `--rollback-pre`, `--rollback-post`
- Improved: `:apply_item`/`:rollback_item` track results via `ITEM_SKIPPED` flag
- Improved: Main menu with `[R]` rollback pre-deployment, `[T]` rollback post-deployment options
- Improved: Interactive select, one-click, and CLI execution all output report summary
- Improved: All `do_apply_*`/`do_rollback_*` set `ITEM_SKIPPED=1` flag when skipping

### v1.2.0 (2026-02-09)
- Added: Environment adaptability detection framework (`detect_env`), checks 9 system components at startup
- Added: Environment pre-check report (`show_env_summary`) shown in main menu
- Added: Pre-requisite checks for every apply/rollback function, smart skip when components missing
- Improved: `do_apply_1` skips scheduled task when schtasks unavailable, still creates check script
- Improved: `do_apply_2` PowerShell password generation fallback
- Improved: `do_apply_3` icacls detection + service account existence check
- Improved: `do_apply_5` firewall service runtime check (MpsSvc), skip if start fails
- Improved: `do_apply_6` Defender full chain check (service + running + ASR version compatibility)
- Improved: `do_apply_7` auditpol availability check + locale adaptation hints
- Improved: `do_apply_10` whitelist config separated from firewall rules, independent checks
- Improved: `do_apply_12` bcdedit/PowerShell checked independently, no mutual dependency
- Improved: All rollback functions check tool availability before execution

### v1.0.0 (2026-02-05)
- Initial release
- Interactive multi-select interface for freely choosing hardening items
- Support entering multiple digits to toggle multiple options simultaneously
- Select all/deselect all shortcuts (A/N)
- Support full security hardening workflow
- Support both BAT and PowerShell scripts
- Support security audit report generation
- Support emergency rollback

## License

This project is licensed under the Apache License 2.0. See [LICENSE](../LICENSE) file for details.

## Contributing

Issues and Pull Requests are welcome!

---

**Author**: Alex  
**Email**: unix_sec@163.com  
**Project**: OpenClaw Windows Security Hardening Scripts  
**Version**: 1.3.0
