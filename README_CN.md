# OpenClaw Windows 10 安全加固脚本

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue.svg)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-purple.svg)](https://docs.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

## 概述

本项目提供了一套完整的 Windows 10/11 安全加固脚本，用于在企业环境中安全部署 OpenClaw AI Gateway。脚本遵循 CIS Windows 安全基准和微软最佳安全实践，实现自动化的安全配置。

## 作者信息

| 项目 | 信息 |
|------|------|
| **作者** | Alex |
| **邮箱** | unix_sec@163.com |
| **版本** | 1.2.0 |
| **创建日期** | 2026-02-05 |
| **最后更新** | 2026-02-09 |

## v1.2 新增功能 (环境适配性)

| 功能 | 说明 |
|------|------|
| **环境预检** | 启动时自动检测防火墙/Defender/AppLocker/auditpol/PowerShell/bcdedit 等组件 |
| **智能跳过** | 缺失组件时优雅跳过对应加固项，给出原因和替代建议 |
| **服务状态检查** | 防火墙/Defender 执行前检查服务是否运行，启动失败则跳过 |
| **环境报告** | 主菜单显示所有组件可用性检测结果 |
| **降级处理** | PowerShell 不可用时密码生成自动降级；各组件独立检查互不影响 |

## v1.1 功能

| 功能 | 说明 |
|------|------|
| **幂等执行** | 可重复运行，自动跳过已完成项 |
| **单独回退** | 支持回退指定的加固项 |
| **完整日志** | 所有操作均有详细日志记录 |
| **调试模式** | 支持单独调试指定功能项 |
| **状态管理** | 状态文件记录加固状态 |

## 功能特性

### 核心功能

- ✅ **服务账户管理** - 创建最小权限的专用服务账户
- ✅ **文件权限加固** - NTFS ACL 权限配置，移除不必要的访问权限
- ✅ **防火墙配置** - Windows 防火墙规则，阻止未授权访问
- ✅ **Defender 配置** - Windows Defender 实时保护和 ASR 规则
- ✅ **审计策略** - 安全事件审计，支持 SIEM 集成
- ✅ **安全配置生成** - 自动生成安全的配置文件和 Token
- ✅ **安全审计报告** - 一键检查当前安全状态
- ✅ **紧急回滚** - 快速恢复默认配置

### 安全加固项目

| 加固项 | 描述 | 严重性 |
|--------|------|--------|
| 服务账户隔离 | 使用专用低权限账户运行服务 | 高 |
| 配置文件权限 | 移除 Everyone/Users 对敏感文件的访问 | 高 |
| 网络隔离 | Gateway 仅绑定到本地回环地址 | 高 |
| 防火墙规则 | 阻止外部对 Gateway 端口的访问 | 高 |
| 实时保护 | 启用 Windows Defender 实时扫描 | 中 |
| 行为监控 | 启用可疑行为检测 | 中 |
| ASR 规则 | 攻击面缩减规则 | 中 |
| 安全审计 | 启用登录、进程、文件访问审计 | 中 |

## 系统要求

### 最低要求

- **操作系统**: Windows 10 版本 1809+ / Windows 11 / Windows Server 2016+
- **PowerShell**: 5.1 或更高版本
- **权限**: 管理员权限
- **磁盘空间**: 100 MB（用于日志和配置）

### 推荐环境

- Windows 10 企业版 / Windows 11 企业版
- PowerShell 7.x
- Windows Defender（非第三方防病毒软件）
- 域环境（用于组策略集成）


## 快速开始

### 交互式运行

1. 右键点击 `windows-security-hardening.bat`
2. 选择 **"以管理员身份运行"**
3. 在主菜单选择操作

### 命令行运行

```cmd
REM 交互式菜单
windows-security-hardening.bat

REM 模拟运行 (不实际执行)
windows-security-hardening.bat --dry-run

REM 查看加固状态
windows-security-hardening.bat --status

REM 回退指定加固项
windows-security-hardening.bat --rollback 5

REM 调试指定加固项
windows-security-hardening.bat --debug 3

REM 应用指定加固项
windows-security-hardening.bat --apply 1
```

### 命令行参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--help` | 显示帮助信息 | `script.bat --help` |
| `--dry-run` | 模拟运行 | `script.bat --dry-run` |
| `--status` | 查看加固状态 | `script.bat --status` |
| `--rollback N` | 回退加固项 N | `script.bat --rollback 5` |
| `--debug N` | 调试加固项 N | `script.bat --debug 3` |
| `--apply N` | 应用加固项 N | `script.bat --apply 1` |

### 交互式菜单选项

| 选项 | 功能 |
|------|------|
| 1 | 交互式选择加固项 |
| 2 | 一键完整加固 |
| 3 | 查看加固状态 |
| 4 | 回退指定加固项 |
| 5 | 调试指定加固项 |
| 6 | 查看日志 |
| 7 | 全部回退 |

## 幂等性说明

脚本支持幂等执行，可以安全地重复运行：

- **服务账户**: 已存在则跳过创建
- **配置文件**: 已存在则保留原文件
- **防火墙规则**: 先删除再添加，避免重复
- **状态文件**: 记录每项加固状态

状态文件: `C:\OpenClaw\hardening-state\state.txt`

## 日志说明

所有操作均记录到日志文件：

- **日志目录**: `C:\OpenClaw\hardening-logs\`
- **日志格式**: `[日期 时间] [级别] 消息`

```cmd
REM 查看最近日志
type C:\OpenClaw\hardening-logs\hardening-*.log | more

REM 查看特定加固项日志
findstr "item=5" C:\OpenClaw\hardening-logs\hardening-*.log
```

## 调试模式

调试模式支持对单个加固项进行测试：

```cmd
REM 进入调试模式
windows-security-hardening.bat --debug 5

REM 调试菜单选项:
REM [1] 执行加固
REM [2] 执行回退
REM [3] 模拟执行加固
REM [4] 模拟执行回退
REM [5] 查看日志
```

## 详细使用说明

### BAT 脚本 - 主菜单

| 选项 | 功能 | 说明 |
|------|------|------|
| 1 | **交互式选择加固项** | 进入多选界面，自由选择要执行的加固项（推荐） |
| 2 | 一键完整加固 | 一次性执行所有加固项 |
| 3 | 生成安全审计报告 | 检查当前安全配置状态 |
| 4 | 撤销安全加固 | 紧急恢复默认配置 |
| 0 | 退出 | 退出脚本 |

### BAT 脚本 - 交互式选择界面

进入交互式选择后，可使用以下操作：

| 操作 | 说明 |
|------|------|
| `1-7` | 切换对应加固项的选中状态（再次输入取消选择） |
| `123` | 同时切换多个加固项（支持连续输入多个数字） |
| `A` | **全选**所有加固项 |
| `N` | 取消全部选择 |
| `E` | 执行选中的加固项 |
| `B` | 返回主菜单 |

### 可选择的加固项

| 编号 | 加固项 | 说明 |
|------|--------|------|
| 1 | 创建服务账户 | 创建低权限的 openclaw_svc 账户 |
| 2 | 配置文件权限 | 配置 NTFS ACL 权限 |
| 3 | 配置防火墙 | 配置 Windows 防火墙规则 |
| 4 | 配置 Windows Defender | 启用保护功能和 ASR 规则 |
| 5 | 启用审计策略 | 配置安全事件审计 |
| 6 | 生成安全配置 | 生成安全配置文件和 Token |
| 7 | 安装服务 | 使用 NSSM 安装 Windows 服务 |

### PowerShell 脚本参数

```powershell
.\windows-security-hardening.ps1
    [-Action <String>]          # 执行的操作
    [-ServiceAccount <String>]  # 服务账户名称（默认: openclaw_svc）
    [-GatewayPort <Int>]        # Gateway 端口（默认: 18789）
    [-OpenClawDir <String>]     # OpenClaw 安装目录（默认: C:\OpenClaw）
    [-Force]                    # 强制执行，跳过确认
    [-WhatIf]                   # 预览模式，不实际执行
```

#### Action 参数值

| 值 | 说明 |
|------|------|
| `All` | 执行完整安全加固（默认） |
| `Account` | 仅创建服务账户 |
| `Permissions` | 仅配置文件权限 |
| `Firewall` | 仅配置防火墙 |
| `Defender` | 仅配置 Windows Defender |
| `Audit` | 仅启用审计策略 |
| `Service` | 安装服务（需要 NSSM） |
| `Report` | 生成安全审计报告 |
| `Rollback` | 撤销安全加固 |

### BAT 脚本使用示例

```
========================================
交互式选择界面示例
========================================

[ ] [1] 创建服务账户
[√] [2] 配置文件权限      <- 已选中
[√] [3] 配置防火墙        <- 已选中
[ ] [4] 配置 Windows Defender
[ ] [5] 启用审计策略
[√] [6] 生成安全配置      <- 已选中
[ ] [7] 安装服务

请输入选项: 236     <- 输入 236 切换这三项的状态
请输入选项: A       <- 输入 A 全选所有项
请输入选项: E       <- 输入 E 执行选中的加固项
```

### PowerShell 脚本使用示例

```powershell
# 示例 1: 完整安全加固
.\windows-security-hardening.ps1 -Action All

# 示例 2: 预览模式（不实际执行）
.\windows-security-hardening.ps1 -Action All -WhatIf

# 示例 3: 自定义服务账户和端口
.\windows-security-hardening.ps1 -Action All -ServiceAccount "my_openclaw" -GatewayPort 8080

# 示例 4: 仅生成安全审计报告
.\windows-security-hardening.ps1 -Action Report

# 示例 5: 强制撤销加固（跳过确认）
.\windows-security-hardening.ps1 -Action Rollback -Force
```

## 配置说明

### 默认配置

脚本使用以下默认配置，可根据需要修改：

```powershell
$Config = @{
    OpenClawDir    = "C:\OpenClaw"              # OpenClaw 安装目录
    StateDir       = "$env:USERPROFILE\.openclaw" # 状态目录
    LogsDir        = "C:\Logs\OpenClaw"         # 日志目录
    SecretsDir     = "C:\OpenClaw\secrets"      # 密钥目录
    ServiceAccount = "openclaw_svc"             # 服务账户
    GatewayPort    = 18789                      # Gateway 端口
}
```

### 目录权限配置

| 目录 | 权限配置 |
|------|----------|
| `C:\OpenClaw` | SYSTEM: 完全控制, Administrators: 完全控制, openclaw_svc: 读取执行 |
| `%USERPROFILE%\.openclaw` | SYSTEM: 完全控制, Administrators: 完全控制, openclaw_svc: 修改, 当前用户: 完全控制 |
| `C:\OpenClaw\secrets` | SYSTEM: 完全控制, Administrators: 完全控制, openclaw_svc: 只读 |
| `C:\Logs\OpenClaw` | SYSTEM: 完全控制, Administrators: 完全控制, openclaw_svc: 修改 |

## 安全审计报告

运行安全审计报告会检查以下项目：

| 检查项 | 期望结果 |
|--------|----------|
| 服务账户存在 | ✅ PASS |
| 服务账户不在管理员组 | ✅ PASS |
| 配置文件权限正确 | ✅ PASS |
| 防火墙已启用 | ✅ PASS |
| 防火墙规则已配置 | ✅ PASS |
| Gateway 端口未对外暴露 | ✅ PASS |
| Windows Defender 运行中 | ✅ PASS |
| 实时保护已启用 | ✅ PASS |
| 服务未以 LocalSystem 运行 | ✅ PASS |

### 报告输出示例

```
========================================
OpenClaw Windows 安全审计报告
========================================
日期: 2026-02-05 14:30:00

[1] 检查服务账户...
  [PASS] 服务账户存在
  [PASS] 服务账户不在管理员组中

[2] 检查文件权限...
  [PASS] config.yaml 权限配置正确

[3] 检查防火墙...
  [PASS] Windows 防火墙已启用
  [PASS] OpenClaw 防火墙规则已配置

[4] 检查端口暴露...
  [PASS] Gateway 端口未对外暴露

[5] 检查 Windows Defender...
  [PASS] 实时保护已启用
  [PASS] 行为监控已启用

[6] 检查服务...
  [INFO] 服务状态: Running
  [PASS] 服务账户: .\openclaw_svc

========================================
审计摘要
========================================
未发现严重安全问题
```

## 加固后的后续步骤

1. **更改服务账户密码**
   ```batch
   net user openclaw_svc *
   ```

2. **查看生成的 Gateway Token**
   ```batch
   type C:\OpenClaw\secrets\gateway-token.txt
   ```

3. **启动 OpenClaw 服务**（如果已安装）
   ```batch
   net start OpenClawGateway
   ```

4. **定期运行安全审计**
   ```powershell
   .\windows-security-hardening.ps1 -Action Report
   ```

5. **配置计划任务进行定期审计**
   ```powershell
   # 创建每日安全审计任务
   $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
       -Argument "-File C:\OpenClaw\scripts\windows-security-hardening.ps1 -Action Report"
   $Trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
   Register-ScheduledTask -TaskName "OpenClaw Security Audit" -Action $Action -Trigger $Trigger
   ```

## 故障排除

### 常见问题

#### Q1: 脚本提示"请以管理员身份运行"

**解决方案**: 右键点击脚本，选择"以管理员身份运行"

#### Q2: PowerShell 执行策略阻止脚本运行

**解决方案**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Q3: 服务账户创建失败

**解决方案**: 检查是否有同名账户存在，或使用不同的账户名：
```powershell
.\windows-security-hardening.ps1 -Action Account -ServiceAccount "my_openclaw_svc"
```

#### Q4: 防火墙规则配置失败

**解决方案**: 确保 Windows Firewall 服务正在运行：
```powershell
Get-Service -Name MpsSvc | Start-Service
```

#### Q5: 如何完全撤销加固配置？

**解决方案**:
```powershell
.\windows-security-hardening.ps1 -Action Rollback -Force
```

### 日志位置

所有操作日志保存在：
```
%TEMP%\openclaw-hardening-YYYYMMDD-HHmmss.log
```

## 安全建议

1. **定期更新** - 保持 Windows 和脚本更新到最新版本
2. **最小权限** - 不要将服务账户添加到管理员组
3. **密码安全** - 使用强密码并定期更换
4. **日志监控** - 定期检查安全日志和审计报告
5. **备份配置** - 加固前备份现有配置
6. **测试环境** - 先在测试环境验证脚本

## 参考资源

- [CIS Microsoft Windows 10 Benchmark](https://www.cisecurity.org/benchmark/microsoft_windows_desktop)
- [Microsoft Security Baselines](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-security-configuration-framework/windows-security-baselines)
- [Windows Defender ASR Rules](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/attack-surface-reduction-rules-reference)
- [NSSM - Non-Sucking Service Manager](https://nssm.cc/)

## 更新日志

### v1.2.0 (2026-02-09)
- 新增: 环境适配性检测框架 (`detect_env`)，启动时检测 9 项系统组件
- 新增: 环境预检报告 (`show_env_summary`)，主菜单展示组件可用性状态
- 新增: 每个加固项/回退项增加前置依赖检查，缺失组件时智能跳过
- 优化: `do_apply_1` schtasks 不可用时跳过定时任务，仅生成检查脚本
- 优化: `do_apply_2` PowerShell 密码生成降级方案
- 优化: `do_apply_3` icacls 检测 + 服务账户存在性检查
- 优化: `do_apply_5` 防火墙服务运行状态检测 (MpsSvc)，启动失败则跳过
- 优化: `do_apply_6` Defender 全链路检查 (服务 + 运行 + ASR 版本兼容)
- 优化: `do_apply_7` auditpol 可用性检测 + 语言环境适配提示
- 优化: `do_apply_10` 白名单配置与防火墙规则分离，各自独立检查
- 优化: `do_apply_12` bcdedit/PowerShell 分别检查，互不影响
- 优化: 所有回退函数增加工具可用性检查

### v1.0.0 (2026-02-05)
- 初始版本发布
- 交互式多选界面，支持自由选择加固项
- 支持输入多个数字同时切换多个选项
- 全选/全不选快捷键 (A/N)
- 支持完整安全加固流程
- 支持 BAT 和 PowerShell 两种脚本
- 支持安全审计报告生成
- 支持紧急回滚功能

## 许可证

本项目采用 Apache License 2.0 许可证。详见 [LICENSE](../LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**作者**: Alex  
**邮箱**: unix_sec@163.com  
**项目**: OpenClaw Windows Security Hardening Scripts  
**版本**: 1.2.0
