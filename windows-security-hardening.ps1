#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    OpenClaw Windows 10/11 一键安全加固脚本 (PowerShell 版本)

.DESCRIPTION
    此脚本用于在 Windows 环境中安全部署 OpenClaw，包括：
    - 创建专用服务账户
    - 配置 NTFS 文件权限
    - 配置 Windows 防火墙
    - 配置 Windows Defender
    - 启用安全审计策略
    - 安装 OpenClaw 服务

.PARAMETER Action
    执行的操作：
    - All: 执行完整安全加固
    - Account: 仅创建服务账户
    - Permissions: 仅配置文件权限
    - Firewall: 仅配置防火墙
    - Defender: 仅配置 Windows Defender
    - Audit: 仅启用审计策略
    - Service: 安装服务
    - Report: 生成安全审计报告
    - Rollback: 撤销安全加固

.PARAMETER ServiceAccount
    服务账户名称，默认为 "openclaw_svc"

.PARAMETER GatewayPort
    Gateway 端口，默认为 18789

.PARAMETER OpenClawDir
    OpenClaw 安装目录，默认为 "C:\OpenClaw"

.EXAMPLE
    .\windows-security-hardening.ps1 -Action All
    执行完整安全加固

.EXAMPLE
    .\windows-security-hardening.ps1 -Action Report
    生成安全审计报告

.NOTES
    版本: 1.1
    许可证: Apache License 2.0
    作者: Alex
    邮箱: unix_sec@163.com
    需要管理员权限运行
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Account", "Permissions", "Firewall", "Defender", "Audit", "Service", "Report", "Rollback")]
    [string]$Action = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceAccount = "openclaw_svc",
    
    [Parameter(Mandatory = $false)]
    [int]$GatewayPort = 18789,
    
    [Parameter(Mandatory = $false)]
    [string]$OpenClawDir = "C:\OpenClaw",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# ============================================================================
# 配置变量
# ============================================================================
$Script:Config = @{
    OpenClawDir      = $OpenClawDir
    StateDir         = "$env:USERPROFILE\.openclaw"
    LogsDir          = "C:\Logs\OpenClaw"
    SecretsDir       = "$OpenClawDir\secrets"
    ServiceAccount   = $ServiceAccount
    GatewayPort      = $GatewayPort
    NodePath         = "C:\Program Files\nodejs"
    LogFile          = "$env:TEMP\openclaw-hardening-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
}

# ============================================================================
# 日志函数
# ============================================================================
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # 写入日志文件
    Add-Content -Path $Script:Config.LogFile -Value $logMessage -ErrorAction SilentlyContinue
    
    # 输出到控制台
    switch ($Level) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARN"    { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage -ForegroundColor Cyan }
    }
}

# ============================================================================
# 检查管理员权限
# ============================================================================
function Test-AdminPrivilege {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
# 创建目录结构
# ============================================================================
function Initialize-Directories {
    Write-Log "创建目录结构..." -Level INFO
    
    $directories = @(
        $Script:Config.OpenClawDir,
        $Script:Config.StateDir,
        $Script:Config.LogsDir,
        $Script:Config.SecretsDir
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            if (-not $WhatIf) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Log "  创建目录: $dir" -Level SUCCESS
            } else {
                Write-Log "  [WhatIf] 将创建目录: $dir" -Level INFO
            }
        } else {
            Write-Log "  目录已存在: $dir" -Level INFO
        }
    }
}

# ============================================================================
# 创建服务账户
# ============================================================================
function New-ServiceAccount {
    Write-Log "创建服务账户: $($Script:Config.ServiceAccount)..." -Level INFO
    
    # 检查账户是否已存在
    $existingUser = Get-LocalUser -Name $Script:Config.ServiceAccount -ErrorAction SilentlyContinue
    if ($existingUser) {
        Write-Log "  服务账户已存在，跳过创建" -Level WARN
        return $true
    }
    
    if ($WhatIf) {
        Write-Log "  [WhatIf] 将创建服务账户: $($Script:Config.ServiceAccount)" -Level INFO
        return $true
    }
    
    # 生成随机密码
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    $password = -join ((1..20) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    
    try {
        # 创建用户
        New-LocalUser -Name $Script:Config.ServiceAccount `
            -Password $securePassword `
            -FullName "OpenClaw Service Account" `
            -Description "Dedicated service account for OpenClaw Gateway" `
            -PasswordNeverExpires $true `
            -UserMayNotChangePassword $true `
            -AccountNeverExpires | Out-Null
        
        Write-Log "  服务账户创建成功" -Level SUCCESS
        Write-Log "  临时密码: $password" -Level WARN
        Write-Log "  请立即更改密码！" -Level WARN
        
        # 保存密码到临时文件
        $passwordFile = "$env:TEMP\openclaw_svc_password.txt"
        $password | Out-File -FilePath $passwordFile -Encoding UTF8
        Write-Log "  密码已保存到: $passwordFile (请立即保存并删除)" -Level WARN
        
        # 从管理员组移除（如果存在）
        Remove-LocalGroupMember -Group "Administrators" -Member $Script:Config.ServiceAccount -ErrorAction SilentlyContinue
        
        # 从 Users 组移除
        Remove-LocalGroupMember -Group "Users" -Member $Script:Config.ServiceAccount -ErrorAction SilentlyContinue
        
        Write-Log "  服务账户配置完成" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "  创建服务账户失败: $_" -Level ERROR
        return $false
    }
}

# ============================================================================
# 配置文件权限
# ============================================================================
function Set-FilePermissions {
    Write-Log "配置文件系统权限..." -Level INFO
    
    $permissionConfigs = @(
        @{
            Path = $Script:Config.OpenClawDir
            Access = @(
                @{ Identity = "SYSTEM"; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = "BUILTIN\Administrators"; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = $Script:Config.ServiceAccount; Rights = "ReadAndExecute"; Inheritance = "ContainerInherit,ObjectInherit" }
            )
        },
        @{
            Path = $Script:Config.StateDir
            Access = @(
                @{ Identity = "SYSTEM"; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = "BUILTIN\Administrators"; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = $Script:Config.ServiceAccount; Rights = "Modify"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = $env:USERNAME; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
            )
        },
        @{
            Path = $Script:Config.SecretsDir
            Access = @(
                @{ Identity = "SYSTEM"; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = "BUILTIN\Administrators"; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = $Script:Config.ServiceAccount; Rights = "Read"; Inheritance = "ContainerInherit,ObjectInherit" }
            )
        },
        @{
            Path = $Script:Config.LogsDir
            Access = @(
                @{ Identity = "SYSTEM"; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = "BUILTIN\Administrators"; Rights = "FullControl"; Inheritance = "ContainerInherit,ObjectInherit" }
                @{ Identity = $Script:Config.ServiceAccount; Rights = "Modify"; Inheritance = "ContainerInherit,ObjectInherit" }
            )
        }
    )
    
    foreach ($config in $permissionConfigs) {
        if (-not (Test-Path $config.Path)) {
            Write-Log "  跳过不存在的路径: $($config.Path)" -Level WARN
            continue
        }
        
        if ($WhatIf) {
            Write-Log "  [WhatIf] 将配置权限: $($config.Path)" -Level INFO
            continue
        }
        
        try {
            $acl = Get-Acl $config.Path
            
            # 禁用继承并清除现有权限
            $acl.SetAccessRuleProtection($true, $false)
            $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) } | Out-Null
            
            # 添加新权限
            foreach ($access in $config.Access) {
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $access.Identity,
                    $access.Rights,
                    $access.Inheritance,
                    "None",
                    "Allow"
                )
                $acl.AddAccessRule($rule)
            }
            
            Set-Acl -Path $config.Path -AclObject $acl
            Write-Log "  配置完成: $($config.Path)" -Level SUCCESS
        }
        catch {
            Write-Log "  配置失败 $($config.Path): $_" -Level ERROR
        }
    }
}

# ============================================================================
# 配置防火墙
# ============================================================================
function Set-FirewallRules {
    Write-Log "配置 Windows 防火墙..." -Level INFO
    
    if ($WhatIf) {
        Write-Log "  [WhatIf] 将配置防火墙规则" -Level INFO
        return
    }
    
    try {
        # 启用防火墙
        Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True
        Write-Log "  防火墙已启用" -Level SUCCESS
        
        # 删除旧规则
        Get-NetFirewallRule -DisplayName "OpenClaw*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
        Write-Log "  已删除旧的防火墙规则" -Level INFO
        
        # 阻止所有入站连接到 Gateway 端口
        New-NetFirewallRule -DisplayName "OpenClaw Gateway - Block All Inbound" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $Script:Config.GatewayPort `
            -Action Block `
            -Profile Any | Out-Null
        Write-Log "  已阻止 Gateway 端口外部访问" -Level SUCCESS
        
        # 允许本地回环
        New-NetFirewallRule -DisplayName "OpenClaw Gateway - Allow Loopback" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $Script:Config.GatewayPort `
            -LocalAddress 127.0.0.1 `
            -RemoteAddress 127.0.0.1 `
            -Action Allow `
            -Profile Any | Out-Null
        Write-Log "  已允许本地回环访问" -Level SUCCESS
        
        # 配置日志
        Set-NetFirewallProfile -Profile Domain, Public, Private `
            -LogFileName "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log" `
            -LogMaxSizeKilobytes 32768 `
            -LogBlocked True `
            -LogAllowed False
        Write-Log "  防火墙日志已配置" -Level SUCCESS
    }
    catch {
        Write-Log "  防火墙配置失败: $_" -Level ERROR
    }
}

# ============================================================================
# 配置 Windows Defender
# ============================================================================
function Set-DefenderSettings {
    Write-Log "配置 Windows Defender..." -Level INFO
    
    # 检查 Defender 是否可用
    $defenderStatus = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if (-not $defenderStatus) {
        Write-Log "  Windows Defender 不可用，跳过配置" -Level WARN
        return
    }
    
    if ($WhatIf) {
        Write-Log "  [WhatIf] 将配置 Windows Defender" -Level INFO
        return
    }
    
    try {
        # 启用实时保护
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Write-Log "  实时保护已启用" -Level SUCCESS
        
        # 启用行为监控
        Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        Write-Log "  行为监控已启用" -Level SUCCESS
        
        # 启用脚本扫描
        Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
        Write-Log "  脚本扫描已启用" -Level SUCCESS
        
        # 启用云保护
        Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
        Set-MpPreference -SubmitSamplesConsent SendSafeSamples -ErrorAction SilentlyContinue
        Write-Log "  云保护已启用" -Level SUCCESS
        
        # 配置 ASR 规则
        $asrRules = @(
            @{ Id = "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC"; Name = "阻止混淆脚本" }
            @{ Id = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2"; Name = "阻止凭据窃取" }
            @{ Id = "d4f940ab-401b-4efc-aadc-ad5f3c50688a"; Name = "阻止Office子进程" }
        )
        
        foreach ($rule in $asrRules) {
            try {
                Add-MpPreference -AttackSurfaceReductionRules_Ids $rule.Id `
                    -AttackSurfaceReductionRules_Actions Enabled -ErrorAction SilentlyContinue
                Write-Log "  ASR 规则已启用: $($rule.Name)" -Level SUCCESS
            }
            catch {
                Write-Log "  ASR 规则配置失败: $($rule.Name)" -Level WARN
            }
        }
    }
    catch {
        Write-Log "  Windows Defender 配置失败: $_" -Level ERROR
    }
}

# ============================================================================
# 配置审计策略
# ============================================================================
function Set-AuditPolicy {
    Write-Log "配置安全审计策略..." -Level INFO
    
    if ($WhatIf) {
        Write-Log "  [WhatIf] 将配置审计策略" -Level INFO
        return
    }
    
    $auditCategories = @(
        @{ Subcategory = "Logon"; Description = "登录审计" }
        @{ Subcategory = "Process Creation"; Description = "进程创建审计" }
        @{ Subcategory = "File System"; Description = "文件系统审计" }
        @{ Subcategory = "Other Object Access Events"; Description = "对象访问审计" }
        @{ Subcategory = "Sensitive Privilege Use"; Description = "权限使用审计" }
    )
    
    foreach ($category in $auditCategories) {
        try {
            auditpol /set /subcategory:"$($category.Subcategory)" /success:enable /failure:enable | Out-Null
            Write-Log "  已启用: $($category.Description)" -Level SUCCESS
        }
        catch {
            Write-Log "  启用失败: $($category.Description)" -Level WARN
        }
    }
    
    # 增加安全日志大小
    try {
        wevtutil sl Security /ms:524288000 | Out-Null
        Write-Log "  安全日志大小已增加到 500MB" -Level SUCCESS
    }
    catch {
        Write-Log "  安全日志大小配置失败" -Level WARN
    }
    
    # 配置目录审计
    if (Test-Path $Script:Config.SecretsDir) {
        try {
            $acl = Get-Acl $Script:Config.SecretsDir
            $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
                "Everyone",
                "Read,Write,Delete",
                "ContainerInherit,ObjectInherit",
                "None",
                "Success,Failure"
            )
            $acl.AddAuditRule($auditRule)
            Set-Acl -Path $Script:Config.SecretsDir -AclObject $acl
            Write-Log "  Secrets 目录审计已配置" -Level SUCCESS
        }
        catch {
            Write-Log "  目录审计配置失败: $_" -Level WARN
        }
    }
}

# ============================================================================
# 生成安全配置
# ============================================================================
function New-SecureConfig {
    Write-Log "生成安全配置文件..." -Level INFO
    
    if ($WhatIf) {
        Write-Log "  [WhatIf] 将生成安全配置文件" -Level INFO
        return
    }
    
    # 生成随机 Gateway Token
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    $token = -join ((1..32) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    
    # 保存 Token
    $tokenFile = Join-Path $Script:Config.SecretsDir "gateway-token.txt"
    $token | Out-File -FilePath $tokenFile -Encoding UTF8 -NoNewline
    Write-Log "  Gateway Token 已保存: $tokenFile" -Level SUCCESS
    
    # 设置 Token 文件权限
    $acl = Get-Acl $tokenFile
    $acl.SetAccessRuleProtection($true, $false)
    $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) } | Out-Null
    
    @("SYSTEM", "BUILTIN\Administrators", $Script:Config.ServiceAccount) | ForEach-Object {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $_, "Read", "None", "None", "Allow"
        )
        $acl.AddAccessRule($rule)
    }
    Set-Acl -Path $tokenFile -AclObject $acl
    
    # 创建配置文件
    $configFile = Join-Path $Script:Config.StateDir "config.yaml"
    if (-not (Test-Path $configFile)) {
        $configContent = @"
# OpenClaw 安全配置 - 由安全加固脚本生成
# 生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

gateway:
  bind: loopback
  port: $($Script:Config.GatewayPort)
  auth:
    mode: token
    # Token 从环境变量 OPENCLAW_GATEWAY_TOKEN_FILE 指定的文件读取
  controlUi:
    enabled: true
    allowInsecureAuth: false
    dangerouslyDisableDeviceAuth: false

logging:
  redactSensitive: tools

tools:
  elevated:
    enabled: false

browser:
  enabled: false
"@
        $configContent | Out-File -FilePath $configFile -Encoding UTF8
        Write-Log "  安全配置文件已创建: $configFile" -Level SUCCESS
    }
    
    # 创建环境变量脚本
    $envScript = Join-Path $Script:Config.OpenClawDir "set-env.ps1"
    $envContent = @"
# OpenClaw 环境变量设置
`$env:OPENCLAW_STATE_DIR = "$($Script:Config.StateDir)"
`$env:OPENCLAW_GATEWAY_TOKEN_FILE = "$tokenFile"
`$env:NODE_ENV = "production"
"@
    $envContent | Out-File -FilePath $envScript -Encoding UTF8
    Write-Log "  环境变量脚本已创建: $envScript" -Level SUCCESS
}

# ============================================================================
# 安全审计报告
# ============================================================================
function Get-SecurityReport {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "OpenClaw Windows 安全审计报告" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""
    
    $issues = 0
    $warnings = 0
    
    # 1. 检查服务账户
    Write-Host "[1] 检查服务账户..." -ForegroundColor Yellow
    $user = Get-LocalUser -Name $Script:Config.ServiceAccount -ErrorAction SilentlyContinue
    if ($user) {
        Write-Host "  [PASS] 服务账户存在" -ForegroundColor Green
        
        $adminGroup = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
        if ($adminGroup.Name -contains "$env:COMPUTERNAME\$($Script:Config.ServiceAccount)") {
            Write-Host "  [FAIL] 服务账户在管理员组中！" -ForegroundColor Red
            $issues++
        } else {
            Write-Host "  [PASS] 服务账户不在管理员组中" -ForegroundColor Green
        }
    } else {
        Write-Host "  [WARN] 服务账户不存在" -ForegroundColor Yellow
        $warnings++
    }
    
    # 2. 检查文件权限
    Write-Host ""
    Write-Host "[2] 检查文件权限..." -ForegroundColor Yellow
    $configPath = Join-Path $Script:Config.StateDir "config.yaml"
    if (Test-Path $configPath) {
        $acl = Get-Acl $configPath
        $unsafeAccess = $acl.Access | Where-Object { 
            $_.IdentityReference -match "Everyone|Users|Authenticated Users" -and 
            $_.FileSystemRights -match "Write|Modify|FullControl"
        }
        if ($unsafeAccess) {
            Write-Host "  [FAIL] config.yaml 权限过于宽松" -ForegroundColor Red
            $issues++
        } else {
            Write-Host "  [PASS] config.yaml 权限配置正确" -ForegroundColor Green
        }
    } else {
        Write-Host "  [WARN] config.yaml 不存在" -ForegroundColor Yellow
        $warnings++
    }
    
    # 3. 检查防火墙
    Write-Host ""
    Write-Host "[3] 检查防火墙..." -ForegroundColor Yellow
    $fwStatus = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $false }
    if ($fwStatus) {
        Write-Host "  [FAIL] 部分防火墙配置文件未启用" -ForegroundColor Red
        $issues++
    } else {
        Write-Host "  [PASS] Windows 防火墙已启用" -ForegroundColor Green
    }
    
    $fwRules = Get-NetFirewallRule -DisplayName "OpenClaw*" -ErrorAction SilentlyContinue
    if ($fwRules) {
        Write-Host "  [PASS] OpenClaw 防火墙规则已配置" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] OpenClaw 防火墙规则未配置" -ForegroundColor Yellow
        $warnings++
    }
    
    # 4. 检查端口暴露
    Write-Host ""
    Write-Host "[4] 检查端口暴露..." -ForegroundColor Yellow
    $listeners = Get-NetTCPConnection -LocalPort $Script:Config.GatewayPort -State Listen -ErrorAction SilentlyContinue
    $exposed = $listeners | Where-Object { $_.LocalAddress -ne "127.0.0.1" -and $_.LocalAddress -ne "::1" }
    if ($exposed) {
        Write-Host "  [FAIL] Gateway 端口对外暴露！" -ForegroundColor Red
        $exposed | ForEach-Object { Write-Host "    $($_.LocalAddress):$($_.LocalPort)" -ForegroundColor Red }
        $issues++
    } else {
        Write-Host "  [PASS] Gateway 端口未对外暴露" -ForegroundColor Green
    }
    
    # 5. 检查 Windows Defender
    Write-Host ""
    Write-Host "[5] 检查 Windows Defender..." -ForegroundColor Yellow
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
        if ($defenderStatus.RealTimeProtectionEnabled) {
            Write-Host "  [PASS] 实时保护已启用" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] 实时保护未启用" -ForegroundColor Red
            $issues++
        }
        
        if ($defenderStatus.BehaviorMonitorEnabled) {
            Write-Host "  [PASS] 行为监控已启用" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] 行为监控未启用" -ForegroundColor Yellow
            $warnings++
        }
    }
    catch {
        Write-Host "  [WARN] Windows Defender 状态未知" -ForegroundColor Yellow
        $warnings++
    }
    
    # 6. 检查服务
    Write-Host ""
    Write-Host "[6] 检查服务..." -ForegroundColor Yellow
    $service = Get-Service -Name "OpenClawGateway" -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "  [INFO] 服务状态: $($service.Status)" -ForegroundColor Cyan
        
        $svcConfig = Get-WmiObject -Class Win32_Service -Filter "Name='OpenClawGateway'"
        if ($svcConfig.StartName -eq "LocalSystem") {
            Write-Host "  [FAIL] 服务以 LocalSystem 运行" -ForegroundColor Red
            $issues++
        } else {
            Write-Host "  [PASS] 服务账户: $($svcConfig.StartName)" -ForegroundColor Green
        }
    } else {
        Write-Host "  [INFO] OpenClaw 服务未安装" -ForegroundColor Cyan
    }
    
    # 摘要
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "审计摘要" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    if ($issues -gt 0) {
        Write-Host "发现 $issues 个安全问题需要修复" -ForegroundColor Red
    } else {
        Write-Host "未发现严重安全问题" -ForegroundColor Green
    }
    if ($warnings -gt 0) {
        Write-Host "发现 $warnings 个警告需要关注" -ForegroundColor Yellow
    }
    Write-Host ""
    
    return @{ Issues = $issues; Warnings = $warnings }
}

# ============================================================================
# 撤销安全加固
# ============================================================================
function Undo-SecurityHardening {
    Write-Log "撤销安全加固..." -Level WARN
    
    if (-not $Force) {
        $confirm = Read-Host "确认撤销安全加固? 输入 'CONFIRM' 继续"
        if ($confirm -ne "CONFIRM") {
            Write-Log "操作已取消" -Level INFO
            return
        }
    }
    
    # 停止并删除服务
    Stop-Service -Name "OpenClawGateway" -Force -ErrorAction SilentlyContinue
    sc.exe delete "OpenClawGateway" | Out-Null
    Write-Log "  服务已删除" -Level SUCCESS
    
    # 删除防火墙规则
    Get-NetFirewallRule -DisplayName "OpenClaw*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    Write-Log "  防火墙规则已删除" -Level SUCCESS
    
    # 重置文件权限
    @($Script:Config.OpenClawDir, $Script:Config.StateDir) | ForEach-Object {
        if (Test-Path $_) {
            icacls $_ /reset /t | Out-Null
        }
    }
    Write-Log "  文件权限已重置" -Level SUCCESS
    
    # 删除服务账户
    Remove-LocalUser -Name $Script:Config.ServiceAccount -ErrorAction SilentlyContinue
    Write-Log "  服务账户已删除" -Level SUCCESS
    
    Write-Log "安全加固已撤销" -Level SUCCESS
}

# ============================================================================
# 主程序
# ============================================================================
function Main {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "OpenClaw Windows 10 安全加固脚本 v1.0" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-AdminPrivilege)) {
        Write-Log "请以管理员身份运行此脚本！" -Level ERROR
        exit 1
    }
    
    Write-Log "开始执行: $Action" -Level INFO
    Write-Log "日志文件: $($Script:Config.LogFile)" -Level INFO
    
    switch ($Action) {
        "All" {
            Initialize-Directories
            New-ServiceAccount
            Set-FilePermissions
            Set-FirewallRules
            Set-DefenderSettings
            Set-AuditPolicy
            New-SecureConfig
            Write-Host ""
            Write-Log "完整安全加固已完成！" -Level SUCCESS
            Write-Host ""
            Write-Host "后续步骤:" -ForegroundColor Yellow
            Write-Host "  1. 设置服务账户密码: net user $($Script:Config.ServiceAccount) *"
            Write-Host "  2. 查看 Gateway Token: $($Script:Config.SecretsDir)\gateway-token.txt"
            Write-Host "  3. 运行安全审计: .\$($MyInvocation.MyCommand.Name) -Action Report"
        }
        "Account" { New-ServiceAccount }
        "Permissions" { Initialize-Directories; Set-FilePermissions }
        "Firewall" { Set-FirewallRules }
        "Defender" { Set-DefenderSettings }
        "Audit" { Set-AuditPolicy }
        "Service" { Write-Log "请使用 bat 脚本安装服务（需要 NSSM）" -Level WARN }
        "Report" { Get-SecurityReport }
        "Rollback" { Undo-SecurityHardening }
    }
    
    Write-Host ""
    Write-Log "操作完成" -Level INFO
}

# 执行主程序
Main
