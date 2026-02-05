# OpenClaw Windows 10 Security Hardening Scripts
## Overview

This project provides a complete set of Windows 10/11 security hardening scripts for securely deploying OpenClaw AI Gateway in enterprise environments. The scripts follow CIS Windows Security Benchmark and Microsoft security best practices for automated security configuration.

**v1.0 New Feature**: Brand new **interactive multi-select interface** allowing users to freely choose which hardening items to execute!

## Author Information

| Item | Information |
|------|-------------|
| **Author** | Alex |
| **Email** | unix_sec@163.com |
| **Version** | 1.0.0 |
| **Created** | 2026-02-05 |
| **Updated** | 2026-02-05 |

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

## File Structure

```
scripts/
├── README.md                        # This document (English)
├── README_CN.md                     # Chinese documentation
├── windows-security-hardening.bat   # BAT script (interactive menu)
└── windows-security-hardening.ps1   # PowerShell script (command-line)
```

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

## License

This project is licensed under the Apache 2.0 License. See [LICENSE](../LICENSE) file for details.

## Contributing

Issues and Pull Requests are welcome!

---

**Author**: Alex  
**Email**: unix_sec@163.com  
**Project**: OpenClaw Windows Security Hardening Scripts  
**Version**: 1.0.0
