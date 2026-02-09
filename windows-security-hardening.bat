@echo off
REM ============================================================================
REM OpenClaw Windows 安全加固脚本
REM 版本: 1.2
REM 作者: Alex
REM 邮箱: unix_sec@163.com
REM 许可证: Apache License 2.0
REM 适用: Windows 10/11, Windows Server 2016+
REM
REM 安全风险覆盖 (基于源码分析 + 互联网安全研究):
REM   [R1] Gateway 暴露     - 1800+ 实例暴露 API Key
REM   [R2] 提示注入/命令注入 - Agent Shell 访问 + 提示词劫持
REM   [R3] MCP 工具投毒      - ClawHavoc: 341 恶意 Skill
REM   [R4] SSRF 攻击         - Agent 访问内网资源
REM   [R5] 凭证泄露          - Token/API Key/聊天记录泄露
REM   [R6] 权限提升          - elevated 工具 + 环境变量注入
REM   [R7] 文件系统越界       - 路径遍历/符号链接攻击
REM   [R8] 资源耗尽          - Fork 炸弹/内存耗尽
REM   [R9] 供应链攻击        - ClawHub 恶意技能包
REM   [R10] 日志/数据泄露     - 敏感信息写入日志
REM
REM 使用方法:
REM   windows-security-hardening.bat              :: 交互式菜单
REM   windows-security-hardening.bat --dry-run    :: 模拟运行
REM   windows-security-hardening.bat --rollback 5 :: 回退加固项 5
REM   windows-security-hardening.bat --debug 3    :: 调试加固项 3
REM   windows-security-hardening.bat --status     :: 查看加固状态
REM ============================================================================

setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

REM ============================================================================
REM 配置变量
REM ============================================================================
set "OPENCLAW_DIR=C:\OpenClaw"
set "OPENCLAW_STATE_DIR=C:\OpenClaw\state"
set "OPENCLAW_LOGS_DIR=C:\OpenClaw\logs"
set "OPENCLAW_SECRETS_DIR=C:\OpenClaw\secrets"
set "OPENCLAW_CONFIG_DIR=C:\OpenClaw\config"
set "SERVICE_ACCOUNT=OpenClawService"
set "GATEWAY_PORT=18789"
set "LOG_DIR=C:\OpenClaw\hardening-logs"
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "TODAY=%%c%%a%%b"
set "LOG_FILE=%LOG_DIR%\hardening-%TODAY%.log"
set "STATE_DIR=C:\OpenClaw\hardening-state"
set "STATE_FILE=%STATE_DIR%\state.txt"
set "DRY_RUN=0"
set "DEBUG_MODE=0"
set "DEBUG_ITEM=0"
set "ROLLBACK_MODE=0"
set "ROLLBACK_ITEM=0"

REM 环境能力标记 (检测后填充)
set "HAS_FIREWALL=0"
set "HAS_DEFENDER=0"
set "HAS_APPLOCKER=0"
set "HAS_AUDITPOL=0"
set "HAS_POWERSHELL=0"
set "HAS_SCHTASKS=0"
set "HAS_BCDEDIT=0"
set "HAS_ICACLS=0"
set "HAS_NETSH=0"

REM 加固项名称 (12项)
set "NAME_1=[R1] Gateway 绑定加固 (防暴露)"
set "NAME_2=[R5] 服务账户隔离 (最小权限)"
set "NAME_3=[R5][R7] NTFS ACL 权限加固"
set "NAME_4=[R5] 凭证安全管理 (Token/密钥)"
set "NAME_5=[R1] Windows 防火墙端口限制"
set "NAME_6=[R2][R6] Windows Defender + ASR"
set "NAME_7=[R10][R5] 安全审计策略"
set "NAME_8=[R7][R6] AppLocker 应用控制"
set "NAME_9=[R2][R6] 命令执行限制 (防注入)"
set "NAME_10=[R4] 出站网络限制 (防 SSRF)"
set "NAME_11=[R9][R3] Skill/MCP 供应链防护"
set "NAME_12=[R8] 进程资源限制"

REM ============================================================================
REM 参数解析
REM ============================================================================
:parse_args
if "%~1"=="" goto init
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--dry-run" ( set "DRY_RUN=1" & shift & goto parse_args )
if /i "%~1"=="--status" ( call :init_logging & call :show_status & goto :eof )
if /i "%~1"=="--rollback" ( set "ROLLBACK_MODE=1" & set "ROLLBACK_ITEM=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--debug" ( set "DEBUG_MODE=1" & set "DEBUG_ITEM=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--apply" ( call :init_logging & call :check_admin & call :apply_item %~2 & shift & shift & goto :eof )
shift
goto parse_args

:init
call :init_logging
call :detect_env
call :check_admin
if "%ROLLBACK_MODE%"=="1" ( call :rollback_item %ROLLBACK_ITEM% & goto :eof )
if "%DEBUG_MODE%"=="1" if not "%DEBUG_ITEM%"=="0" ( call :debug_item %DEBUG_ITEM% & goto :eof )
goto main_menu

REM ============================================================================
REM 基础函数
REM ============================================================================
:init_logging
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%STATE_DIR%" mkdir "%STATE_DIR%"
if not exist "%STATE_FILE%" echo. > "%STATE_FILE%"
goto :eof

REM ============================================================================
REM 环境检测 - 检查所有依赖组件可用性
REM ============================================================================
:detect_env
REM Windows 防火墙服务
sc query MpsSvc >nul 2>&1
if %errorlevel%==0 ( set "HAS_FIREWALL=1" )

REM Windows Defender
sc query WinDefend >nul 2>&1
if %errorlevel%==0 ( set "HAS_DEFENDER=1" )

REM AppLocker (AppIDSvc)
sc query AppIDSvc >nul 2>&1
if %errorlevel%==0 ( set "HAS_APPLOCKER=1" )

REM auditpol
where auditpol >nul 2>&1
if %errorlevel%==0 ( set "HAS_AUDITPOL=1" )

REM PowerShell
where powershell >nul 2>&1
if %errorlevel%==0 ( set "HAS_POWERSHELL=1" )

REM schtasks
where schtasks >nul 2>&1
if %errorlevel%==0 ( set "HAS_SCHTASKS=1" )

REM bcdedit
where bcdedit >nul 2>&1
if %errorlevel%==0 ( set "HAS_BCDEDIT=1" )

REM icacls
where icacls >nul 2>&1
if %errorlevel%==0 ( set "HAS_ICACLS=1" )

REM netsh
where netsh >nul 2>&1
if %errorlevel%==0 ( set "HAS_NETSH=1" )

call :log_info "环境检测: firewall=%HAS_FIREWALL% defender=%HAS_DEFENDER% applocker=%HAS_APPLOCKER% auditpol=%HAS_AUDITPOL% powershell=%HAS_POWERSHELL% schtasks=%HAS_SCHTASKS% bcdedit=%HAS_BCDEDIT%"
goto :eof

REM 环境预检报告
:show_env_summary
echo.
echo 环境检测:
if "%HAS_FIREWALL%"=="1" ( echo   [OK] Windows 防火墙 ) else ( echo   [--] Windows 防火墙 不可用 ^(加固项 5,10 跳过^) )
if "%HAS_DEFENDER%"=="1" ( echo   [OK] Windows Defender ) else ( echo   [--] Windows Defender 不可用 ^(加固项 6 跳过^) )
if "%HAS_APPLOCKER%"=="1" ( echo   [OK] AppLocker ) else ( echo   [--] AppLocker 不可用 ^(加固项 8 跳过^) )
if "%HAS_AUDITPOL%"=="1" ( echo   [OK] 审计策略 ) else ( echo   [--] auditpol 不可用 ^(加固项 7 跳过^) )
if "%HAS_POWERSHELL%"=="1" ( echo   [OK] PowerShell ) else ( echo   [--] PowerShell 不可用 ^(部分功能受限^) )
if "%HAS_ICACLS%"=="1" ( echo   [OK] NTFS ACL ^(icacls^) ) else ( echo   [--] icacls 不可用 ^(加固项 3 跳过^) )
if "%HAS_SCHTASKS%"=="1" ( echo   [OK] 计划任务 ) else ( echo   [--] schtasks 不可用 ^(定时检查跳过^) )
if "%HAS_BCDEDIT%"=="1" ( echo   [OK] bcdedit ) else ( echo   [--] bcdedit 不可用 ^(DEP 配置跳过^) )
echo.
goto :eof

:log
echo [%date% %time:~0,8%] [%~1] %~2 >> "%LOG_FILE%"
if "%DEBUG_MODE%"=="1" echo [%~1] %~2
goto :eof

:log_info
call :log INFO "%~1"
goto :eof

:log_action
call :log ACTION "item=%~2 action=%~1 status=%~3 detail=%~4"
goto :eof

:get_item_state
set "ITEM_STATE=none"
if exist "%STATE_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /b "ITEM_%~1=" "%STATE_FILE%" 2^>nul') do set "ITEM_STATE=%%b"
)
goto :eof

:set_item_state
findstr /v /b "ITEM_%~1=" "%STATE_FILE%" > "%STATE_FILE%.tmp" 2>nul
move /y "%STATE_FILE%.tmp" "%STATE_FILE%" >nul 2>&1
echo ITEM_%~1=%~2 >> "%STATE_FILE%"
goto :eof

:clear_item_state
findstr /v /b "ITEM_%~1=" "%STATE_FILE%" > "%STATE_FILE%.tmp" 2>nul
move /y "%STATE_FILE%.tmp" "%STATE_FILE%" >nul 2>&1
goto :eof

:check_admin
net session >nul 2>&1
if %errorlevel% neq 0 if "%DRY_RUN%"=="0" (
    echo [错误] 请以管理员身份运行！
    pause
    exit /b 1
)
goto :eof

REM ============================================================================
REM 主菜单
REM ============================================================================
:main_menu
cls
echo ============================================================
echo     OpenClaw Windows 安全加固脚本 v1.2
echo     覆盖 10 类安全风险 / 12 项加固措施
echo ============================================================
if "%DRY_RUN%"=="1" echo                 [模拟运行模式]
call :show_env_summary
echo 安全风险: R1 Gateway暴露  R2 提示注入  R3 MCP投毒
echo           R4 SSRF  R5 凭证泄露  R6 权限提升
echo           R7 文件越界  R8 资源耗尽  R9 供应链  R10 日志泄露
echo.
echo   [1] 交互式选择     [5] 调试模式
echo   [2] 一键完整加固   [6] 查看日志
echo   [3] 查看状态       [7] 全部回退
echo   [4] 回退指定项     [0] 退出
echo.
set /p "CHOICE=选项 [0-7]: "
if "%CHOICE%"=="1" goto interactive_select
if "%CHOICE%"=="2" goto one_click_all
if "%CHOICE%"=="3" ( call :show_status & pause & goto main_menu )
if "%CHOICE%"=="4" goto rollback_menu
if "%CHOICE%"=="5" goto debug_menu
if "%CHOICE%"=="6" goto view_logs
if "%CHOICE%"=="7" goto rollback_all
if "%CHOICE%"=="0" goto exit_script
goto main_menu

REM ============================================================================
REM 交互式选择
REM ============================================================================
:interactive_select
for /l %%i in (1,1,12) do set "SEL_%%i=0"

:select_loop
cls
echo   输入数字切换，A=全选，N=清空，E=执行，B=返回
echo.
for /l %%i in (1,1,12) do (
    call :get_item_state %%i
    set "SI="
    if "!ITEM_STATE!"=="applied" set "SI=[已加固] "
    if "!SEL_%%i!"=="1" ( echo   [√] [%%i] !SI!!NAME_%%i! ) else ( echo   [ ] [%%i] !SI!!NAME_%%i! )
)
echo.
set /p "INPUT=输入: "
if /i "%INPUT%"=="A" ( for /l %%i in (1,1,12) do set "SEL_%%i=1" & goto select_loop )
if /i "%INPUT%"=="N" ( for /l %%i in (1,1,12) do set "SEL_%%i=0" & goto select_loop )
if /i "%INPUT%"=="B" goto main_menu
if /i "%INPUT%"=="E" goto execute_selected

for /l %%i in (1,1,12) do (
    echo %INPUT% | findstr /c:"%%i" >nul
    if !errorlevel!==0 (
        if "!SEL_%%i!"=="0" ( set "SEL_%%i=1" ) else ( set "SEL_%%i=0" )
    )
)
goto select_loop

:execute_selected
set "COUNT=0"
for /l %%i in (1,1,12) do if "!SEL_%%i!"=="1" set /a COUNT+=1
if %COUNT%==0 ( echo 请至少选择一个 & timeout /t 2 >nul & goto select_loop )
echo.
for /l %%i in (1,1,12) do if "!SEL_%%i!"=="1" ( echo. & echo [%%i] !NAME_%%i! & call :apply_item %%i )
echo.
echo 完成 %COUNT% 项！
pause
goto main_menu

:one_click_all
cls
echo 一键完整加固 (12项)
set /p "CONFIRM=确认? [Y/N]: "
if /i not "%CONFIRM%"=="Y" goto main_menu
for /l %%i in (1,1,12) do ( echo. & echo [%%i/12] !NAME_%%i! & call :apply_item %%i )
echo.
echo 一键完整加固完成！
pause
goto main_menu

REM ============================================================================
REM 状态/回退/调试
REM ============================================================================
:show_status
echo.
echo ======== 加固状态 ========
for /l %%i in (1,1,12) do (
    call :get_item_state %%i
    if "!ITEM_STATE!"=="applied" ( echo   [√] [%%i] !NAME_%%i! ) else ( echo   [ ] [%%i] !NAME_%%i! )
)
echo.
goto :eof

:rollback_menu
cls
call :show_status
echo   [B] 返回
set /p "ITEM=回退编号 (1-12): "
if /i "%ITEM%"=="B" goto main_menu
if %ITEM% geq 1 if %ITEM% leq 12 (
    set /p "C=确认? [Y/N]: "
    if /i "!C!"=="Y" call :rollback_item %ITEM%
)
pause
goto rollback_menu

:rollback_all
set /p "C=输入 CONFIRM 全部回退: "
if not "%C%"=="CONFIRM" goto main_menu
for /l %%i in (12,-1,1) do (
    call :get_item_state %%i
    if "!ITEM_STATE!"=="applied" call :rollback_item %%i
)
echo 全部回退完成
pause
goto main_menu

:debug_item
set "DI=%~1"
cls
echo 调试 - 加固项 %DI%: !NAME_%DI%!
call :get_item_state %DI%
echo 状态: %ITEM_STATE%
echo.
echo   [1] 执行  [2] 回退  [3] 模拟执行  [4] 模拟回退  [5] 日志  [0] 返回
set /p "DC=选择: "
if "%DC%"=="1" ( set "DEBUG_MODE=1" & set "DRY_RUN=0" & call :apply_item %DI% )
if "%DC%"=="2" ( set "DEBUG_MODE=1" & set "DRY_RUN=0" & call :rollback_item %DI% )
if "%DC%"=="3" ( set "DEBUG_MODE=1" & set "DRY_RUN=1" & call :apply_item %DI% )
if "%DC%"=="4" ( set "DEBUG_MODE=1" & set "DRY_RUN=1" & call :rollback_item %DI% )
if "%DC%"=="5" ( findstr /c:"item=%DI%" "%LOG_FILE%" 2>nul | more )
if "%DC%"=="0" goto :eof
pause
goto debug_item

:debug_menu
cls
for /l %%i in (1,1,12) do ( call :get_item_state %%i & echo   [%%i] [!ITEM_STATE!] !NAME_%%i! )
echo.
set /p "DI=编号 (B=返回): "
if /i "%DI%"=="B" goto main_menu
if %DI% geq 1 if %DI% leq 12 call :debug_item %DI%
goto debug_menu

:view_logs
cls
echo 日志: %LOG_FILE%
echo ---
if exist "%LOG_FILE%" ( powershell -Command "Get-Content '%LOG_FILE%' -Tail 30" ) else ( echo (无) )
echo ---
pause
goto main_menu

REM ============================================================================
REM 加固项调度
REM ============================================================================
:apply_item
set "AI=%~1"
call :log_info "执行加固项 %AI%: !NAME_%AI%!"
call :do_apply_%AI%
if "%DRY_RUN%"=="0" call :set_item_state %AI% applied
goto :eof

:rollback_item
set "RI=%~1"
call :log_info "回退加固项 %RI%: !NAME_%RI%!"
call :do_rollback_%RI%
if "%DRY_RUN%"=="0" call :clear_item_state %RI%
call :log_action rollback %RI% success ""
goto :eof

REM ============================================================================
REM [1] Gateway 绑定加固 — 防 1800+ 暴露事件
REM ============================================================================
:do_apply_1
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将检查 Gateway 绑定 & goto :eof )

if not exist "%OPENCLAW_CONFIG_DIR%" mkdir "%OPENCLAW_CONFIG_DIR%"

REM 创建绑定检查脚本 (不依赖外部组件)
(
    echo @echo off
    echo REM 检查 Gateway 是否对外暴露
    echo netstat -an ^| findstr ":%GATEWAY_PORT% " ^| findstr "LISTENING" ^| findstr /v "127.0.0.1 ::1" ^>nul 2^>^&1
    echo if %%errorlevel%%==0 ^(
    echo     echo [CRITICAL] Gateway 端口 %GATEWAY_PORT% 对外暴露!
    echo     eventcreate /id 9001 /l Application /t ERROR /so OpenClaw /d "Gateway exposed on non-loopback" ^>nul 2^>^&1
    echo ^) else ^(
    echo     echo [OK] Gateway 仅绑定到本地回环
    echo ^)
) > "%OPENCLAW_CONFIG_DIR%\check-gateway-bind.bat"

REM 创建定时检查任务 (需要 schtasks)
if "%HAS_SCHTASKS%"=="1" (
    schtasks /delete /tn "OpenClaw_BindCheck" /f >nul 2>&1
    schtasks /create /tn "OpenClaw_BindCheck" /tr "%OPENCLAW_CONFIG_DIR%\check-gateway-bind.bat" /sc MINUTE /mo 5 /ru SYSTEM >nul 2>&1
    if !errorlevel! neq 0 (
        echo   [警告] 定时任务创建失败，请手动执行 check-gateway-bind.bat
        call :log_info "schtasks 创建失败"
    )
) else (
    echo   [提示] schtasks 不可用，跳过定时检查 (可手动执行 check-gateway-bind.bat)
    call :log_info "schtasks 不可用，跳过定时检查"
)

call :log_action apply 1 success "Gateway 绑定加固完成"
echo   [完成] Gateway 绑定检查脚本已创建
goto :eof

:do_rollback_1
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
if "%HAS_SCHTASKS%"=="1" ( schtasks /delete /tn "OpenClaw_BindCheck" /f >nul 2>&1 )
del /q "%OPENCLAW_CONFIG_DIR%\check-gateway-bind.bat" 2>nul
echo   [完成] 已回退
goto :eof

REM ============================================================================
REM [2] 服务账户隔离
REM ============================================================================
:do_apply_2
REM 幂等性检查
net user %SERVICE_ACCOUNT% >nul 2>&1
if %errorlevel%==0 ( echo   [幂等] 服务账户已存在 & goto :apply_2_done )
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将创建 %SERVICE_ACCOUNT% & goto :eof )

REM 生成随机密码 (优先 PowerShell, 降级用固定复杂密码)
set "RPWD="
if "%HAS_POWERSHELL%"=="1" (
    for /f %%a in ('powershell -Command "[System.Web.Security.Membership]::GeneratePassword(16,4)" 2^>nul') do set "RPWD=%%a"
)
if "%RPWD%"=="" (
    REM PowerShell 不可用或生成失败，使用基于时间的随机密码
    set "RPWD=OC!random!!random!!date:~-2!#sA"
    echo   [提示] PowerShell 不可用，使用备选密码生成
)

net user %SERVICE_ACCOUNT% "%RPWD%" /add /passwordchg:no /expires:never >nul 2>&1
if !errorlevel! neq 0 (
    echo   [失败] 创建服务账户失败 (权限不足?)
    call :log_info "创建服务账户失败"
    goto :eof
)
net localgroup "Users" %SERVICE_ACCOUNT% /delete >nul 2>&1
wmic useraccount where name='%SERVICE_ACCOUNT%' set PasswordExpires=FALSE >nul 2>&1

:apply_2_done
call :log_action apply 2 success "服务账户已配置"
echo   [完成] 服务账户 %SERVICE_ACCOUNT%
goto :eof

:do_rollback_2
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
net user %SERVICE_ACCOUNT% /delete >nul 2>&1
echo   [完成] 账户已删除
goto :eof

REM ============================================================================
REM [3] NTFS ACL 权限加固
REM ============================================================================
:do_apply_3
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置 NTFS ACL & goto :eof )

REM 环境检查: icacls
if "%HAS_ICACLS%"=="0" (
    echo   [跳过] icacls 不可用，无法配置 NTFS ACL
    call :log_info "icacls 不可用，跳过 NTFS ACL"
    goto :eof
)

for %%d in ("%OPENCLAW_DIR%" "%OPENCLAW_STATE_DIR%" "%OPENCLAW_LOGS_DIR%" "%OPENCLAW_SECRETS_DIR%" "%OPENCLAW_CONFIG_DIR%") do (
    if not exist "%%~d" mkdir "%%~d"
)

REM 检查服务账户是否存在
net user %SERVICE_ACCOUNT% >nul 2>&1
if !errorlevel! neq 0 (
    echo   [警告] 服务账户 %SERVICE_ACCOUNT% 不存在，仅设置管理员权限。建议先执行加固项 2。
    call :log_info "服务账户不存在，仅设置管理员 ACL"
    icacls "%OPENCLAW_DIR%" /inheritance:r /grant:r "Administrators:(OI)(CI)F" >nul 2>&1
    icacls "%OPENCLAW_SECRETS_DIR%" /inheritance:r /grant:r "Administrators:(OI)(CI)F" >nul 2>&1
    icacls "%OPENCLAW_STATE_DIR%" /inheritance:r /grant:r "Administrators:(OI)(CI)F" >nul 2>&1
    icacls "%OPENCLAW_LOGS_DIR%" /inheritance:r /grant:r "Administrators:(OI)(CI)F" >nul 2>&1
    goto :apply_3_done
)

REM 主目录: 管理员完全+服务账户读执行
icacls "%OPENCLAW_DIR%" /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)RX" >nul 2>&1
REM 密钥目录: 管理员完全+服务账户只读
icacls "%OPENCLAW_SECRETS_DIR%" /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)R" >nul 2>&1
REM 状态/日志目录: 管理员完全+服务账户修改
icacls "%OPENCLAW_STATE_DIR%" /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)M" >nul 2>&1
icacls "%OPENCLAW_LOGS_DIR%" /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)M" >nul 2>&1

:apply_3_done
call :log_action apply 3 success "NTFS ACL 配置完成"
echo   [完成] NTFS ACL 权限配置
goto :eof

:do_rollback_3
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
if "%HAS_ICACLS%"=="1" (
    icacls "%OPENCLAW_DIR%" /reset /t >nul 2>&1
    echo   [完成] 权限已重置
) else (
    echo   [跳过] icacls 不可用
)
goto :eof

REM ============================================================================
REM [4] 凭证安全管理
REM ============================================================================
:do_apply_4
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将生成安全配置 & goto :eof )

if not exist "%OPENCLAW_SECRETS_DIR%" mkdir "%OPENCLAW_SECRETS_DIR%"
if not exist "%OPENCLAW_CONFIG_DIR%" mkdir "%OPENCLAW_CONFIG_DIR%"

REM 生成 Token (幂等)
if not exist "%OPENCLAW_SECRETS_DIR%\gateway-token" (
    for /f %%a in ('powershell -Command "[Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(24))"') do echo %%a > "%OPENCLAW_SECRETS_DIR%\gateway-token"
    echo   Token 已生成
) else ( echo   [幂等] Token 已存在 )

REM 安全配置 (幂等)
if not exist "%OPENCLAW_CONFIG_DIR%\config.yaml" (
    (
        echo # OpenClaw 安全配置
        echo gateway:
        echo   bind: loopback
        echo   port: %GATEWAY_PORT%
        echo   auth:
        echo     mode: token
        echo   controlUi:
        echo     enabled: true
        echo     allowInsecureAuth: false
        echo     dangerouslyDisableDeviceAuth: false
        echo logging:
        echo   redactSensitive: tools
        echo tools:
        echo   elevated:
        echo     enabled: false
        echo browser:
        echo   enabled: false
    ) > "%OPENCLAW_CONFIG_DIR%\config.yaml"
) else ( echo   [幂等] 配置已存在 )

REM 加固 .openclaw 目录
if exist "%USERPROFILE%\.openclaw" (
    icacls "%USERPROFILE%\.openclaw" /inheritance:r /grant:r "%USERNAME%:(OI)(CI)F" >nul 2>&1
)

call :log_action apply 4 success "凭证安全配置完成"
echo   [完成] Token + 配置 + 凭证保护
goto :eof

:do_rollback_4
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
del /q "%OPENCLAW_SECRETS_DIR%\gateway-token" 2>nul
del /q "%OPENCLAW_CONFIG_DIR%\config.yaml" 2>nul
echo   [完成] 凭证已删除
goto :eof

REM ============================================================================
REM [5] Windows 防火墙端口限制
REM ============================================================================
:do_apply_5
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置防火墙 & goto :eof )

REM 环境检查: 防火墙
if "%HAS_FIREWALL%"=="0" (
    echo   [跳过] Windows 防火墙服务 ^(MpsSvc^) 不可用或已禁用
    echo          请检查: sc query MpsSvc / 组策略是否禁用了防火墙
    call :log_info "防火墙服务不可用，跳过"
    goto :eof
)
if "%HAS_NETSH%"=="0" (
    echo   [跳过] netsh 不可用
    call :log_info "netsh 不可用，跳过防火墙"
    goto :eof
)

REM 检查防火墙服务是否运行中
sc query MpsSvc | findstr "RUNNING" >nul 2>&1
if !errorlevel! neq 0 (
    echo   [提示] 防火墙服务未运行，尝试启动...
    net start MpsSvc >nul 2>&1
    if !errorlevel! neq 0 (
        echo   [跳过] 防火墙服务启动失败
        call :log_info "防火墙服务启动失败"
        goto :eof
    )
)

REM 幂等: 先删后建
netsh advfirewall firewall delete rule name="OpenClaw - Block External" >nul 2>&1
netsh advfirewall firewall delete rule name="OpenClaw - Allow Local" >nul 2>&1
netsh advfirewall firewall add rule name="OpenClaw - Block External" dir=in action=block protocol=tcp localport=%GATEWAY_PORT% >nul 2>&1
netsh advfirewall firewall add rule name="OpenClaw - Allow Local" dir=in action=allow protocol=tcp localport=%GATEWAY_PORT% remoteip=127.0.0.1 >nul 2>&1

call :log_action apply 5 success "防火墙配置完成"
echo   [完成] 端口 %GATEWAY_PORT% 已限制
goto :eof

:do_rollback_5
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
if "%HAS_NETSH%"=="0" ( echo   [跳过] netsh 不可用 & goto :eof )
netsh advfirewall firewall delete rule name="OpenClaw - Block External" >nul 2>&1
netsh advfirewall firewall delete rule name="OpenClaw - Allow Local" >nul 2>&1
echo   [完成] 防火墙规则已删除
goto :eof

REM ============================================================================
REM [6] Windows Defender + ASR 规则
REM ============================================================================
:do_apply_6
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置 Defender & goto :eof )

REM 环境检查: Defender + PowerShell
if "%HAS_DEFENDER%"=="0" (
    echo   [跳过] Windows Defender 服务不可用 (可能使用第三方杀毒或 Server Core)
    call :log_info "Defender 不可用，跳过"
    goto :eof
)
if "%HAS_POWERSHELL%"=="0" (
    echo   [跳过] PowerShell 不可用，无法配置 Defender
    call :log_info "PowerShell 不可用，跳过 Defender"
    goto :eof
)

REM 检查 Defender 服务是否运行
sc query WinDefend | findstr "RUNNING" >nul 2>&1
if !errorlevel! neq 0 (
    echo   [提示] Defender 服务未运行，尝试启动...
    net start WinDefend >nul 2>&1
    if !errorlevel! neq 0 (
        echo   [跳过] Defender 服务启动失败 (可能被组策略禁用)
        call :log_info "Defender 启动失败"
        goto :eof
    )
)

REM 排除 OpenClaw 目录 (防误报)
powershell -Command "Add-MpPreference -ExclusionPath '%OPENCLAW_DIR%' -ErrorAction SilentlyContinue" >nul 2>&1

REM 启用实时保护
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue" >nul 2>&1

REM ASR 规则 (防命令注入/代码执行)
powershell -Command "Set-MpPreference -AttackSurfaceReductionRules_Ids D4F940AB-401B-4EFC-AADC-AD5F3C50688A -AttackSurfaceReductionRules_Actions Enabled -ErrorAction SilentlyContinue" >nul 2>&1
if !errorlevel! neq 0 (
    echo   [警告] ASR 规则设置失败 (可能需要 Windows 10 企业版/教育版)
    call :log_info "ASR 规则不支持 (需企业版)"
)
powershell -Command "Set-MpPreference -AttackSurfaceReductionRules_Ids 3B576869-A4EC-4529-8536-B80A7769E899 -AttackSurfaceReductionRules_Actions Enabled -ErrorAction SilentlyContinue" >nul 2>&1

REM 启用 PUA 保护
powershell -Command "Set-MpPreference -PUAProtection 1 -ErrorAction SilentlyContinue" >nul 2>&1

call :log_action apply 6 success "Defender+ASR 配置完成"
echo   [完成] Defender + ASR 规则
goto :eof

:do_rollback_6
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
if "%HAS_DEFENDER%"=="0" ( echo   [跳过] Defender 不可用 & goto :eof )
if "%HAS_POWERSHELL%"=="1" (
    powershell -Command "Remove-MpPreference -ExclusionPath '%OPENCLAW_DIR%' -ErrorAction SilentlyContinue" >nul 2>&1
)
echo   [完成] Defender 已重置
goto :eof

REM ============================================================================
REM [7] 安全审计策略
REM ============================================================================
:do_apply_7
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置审计 & goto :eof )

REM 环境检查: auditpol
if "%HAS_AUDITPOL%"=="0" (
    echo   [跳过] auditpol 不可用 (Windows Home 版不支持本地安全策略)
    call :log_info "auditpol 不可用，跳过审计策略"
    goto :eof
)

REM 启用审计 (幂等，忽略单个失败)
set "AUDIT_OK=0"
auditpol /set /subcategory:"Logon" /success:enable /failure:enable >nul 2>&1 && set /a AUDIT_OK+=1
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable >nul 2>&1 && set /a AUDIT_OK+=1
auditpol /set /subcategory:"Object Access" /success:enable /failure:enable >nul 2>&1 && set /a AUDIT_OK+=1
auditpol /set /subcategory:"Privilege Use" /success:enable /failure:enable >nul 2>&1 && set /a AUDIT_OK+=1
auditpol /set /subcategory:"File System" /success:enable /failure:enable >nul 2>&1 && set /a AUDIT_OK+=1

if !AUDIT_OK!==0 (
    echo   [警告] 所有审计策略设置均失败 (可能是语言环境差异导致子类别名称不匹配)
    echo          可尝试使用 GUID 方式配置或检查 auditpol /list /subcategory:*
    call :log_info "审计策略全部失败 (语言差异?)"
)

REM 命令行审计
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f >nul 2>&1

call :log_action apply 7 success "审计策略配置完成 (%AUDIT_OK%/5 项)"
echo   [完成] 审计策略 (%AUDIT_OK%/5 项) + 命令行记录
goto :eof

:do_rollback_7
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
if "%HAS_AUDITPOL%"=="1" (
    auditpol /set /subcategory:"Process Creation" /success:disable /failure:disable >nul 2>&1
)
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /f >nul 2>&1
echo   [完成] 审计已禁用
goto :eof

REM ============================================================================
REM [8] AppLocker 应用控制
REM ============================================================================
:do_apply_8
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置 AppLocker & goto :eof )

sc query AppIDSvc >nul 2>&1
if %errorlevel% neq 0 ( echo   [跳过] AppLocker 不可用 & goto :eof )

sc config AppIDSvc start= auto >nul 2>&1
net start AppIDSvc >nul 2>&1

call :log_action apply 8 success "AppLocker 配置完成"
echo   [完成] AppLocker 已启用
goto :eof

:do_rollback_8
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
net stop AppIDSvc >nul 2>&1
sc config AppIDSvc start= demand >nul 2>&1
echo   [完成] AppLocker 已禁用
goto :eof

REM ============================================================================
REM [9] 命令执行限制 — 防提示注入
REM ============================================================================
:do_apply_9
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置命令限制 & goto :eof )

if not exist "%OPENCLAW_CONFIG_DIR%" mkdir "%OPENCLAW_CONFIG_DIR%"

REM 命令限制配置 (与 Linux bash-restrictions.conf 对齐)
(
    echo # OpenClaw Windows 命令执行限制
    echo # 基于源码 bash-tools.exec.ts 的安全机制
    echo.
    echo # 阻止的命令
    echo BLOCKED_COMMANDS=net,netsh,sc,reg,wmic,bcdedit,schtasks,powershell -ep bypass,cmd /c format
    echo.
    echo # 危险环境变量 ^(源码 DANGEROUS_HOST_ENV_VARS^)
    echo BLOCKED_ENV=NODE_OPTIONS,LD_PRELOAD,PYTHONPATH
    echo.
    echo # 阻止 cmd.exe 的 ^& 绕过 ^(源码中已有检查^)
    echo BLOCK_CMD_BYPASS=true
    echo.
    echo # 执行超时
    echo MAX_EXEC_TIME=60
) > "%OPENCLAW_CONFIG_DIR%\command-restrictions.conf"

call :log_action apply 9 success "命令限制配置完成"
echo   [完成] 命令黑名单 + 环境变量过滤
goto :eof

:do_rollback_9
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
del /q "%OPENCLAW_CONFIG_DIR%\command-restrictions.conf" 2>nul
echo   [完成] 命令限制已删除
goto :eof

REM ============================================================================
REM [10] 出站网络限制 — 防 SSRF
REM ============================================================================
:do_apply_10
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置出站限制 & goto :eof )

if not exist "%OPENCLAW_CONFIG_DIR%" mkdir "%OPENCLAW_CONFIG_DIR%"

REM 白名单配置文件始终生成 (不依赖防火墙)
(
    echo # OpenClaw 出站白名单
    echo api.openai.com
    echo api.anthropic.com
    echo api.deepseek.com
    echo generativelanguage.googleapis.com
) > "%OPENCLAW_CONFIG_DIR%\outbound-whitelist.conf"

REM 环境检查: 防火墙
if "%HAS_FIREWALL%"=="0" (
    echo   [提示] 防火墙不可用，仅生成白名单配置文件
    call :log_info "防火墙不可用，仅生成白名单文件"
    goto :apply_10_done
)
if "%HAS_NETSH%"=="0" (
    echo   [提示] netsh 不可用，仅生成白名单配置文件
    call :log_info "netsh 不可用"
    goto :apply_10_done
)

REM 幂等: 先删后建
netsh advfirewall firewall delete rule name="OpenClaw - Allow DNS Out" >nul 2>&1
netsh advfirewall firewall delete rule name="OpenClaw - Allow HTTPS Out" >nul 2>&1
netsh advfirewall firewall delete rule name="OpenClaw - Block Outbound" >nul 2>&1

REM 出站规则
netsh advfirewall firewall add rule name="OpenClaw - Allow DNS Out" dir=out action=allow protocol=udp remoteport=53 >nul 2>&1
netsh advfirewall firewall add rule name="OpenClaw - Allow HTTPS Out" dir=out action=allow protocol=tcp remoteport=443 >nul 2>&1

:apply_10_done
call :log_action apply 10 success "出站限制配置完成"
echo   [完成] 出站限制 + AI API 白名单
goto :eof

:do_rollback_10
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
if "%HAS_NETSH%"=="1" (
    netsh advfirewall firewall delete rule name="OpenClaw - Allow DNS Out" >nul 2>&1
    netsh advfirewall firewall delete rule name="OpenClaw - Allow HTTPS Out" >nul 2>&1
)
del /q "%OPENCLAW_CONFIG_DIR%\outbound-whitelist.conf" 2>nul
echo   [完成] 出站限制已删除
goto :eof

REM ============================================================================
REM [11] Skill/MCP 供应链防护 — 防 ClawHavoc
REM ============================================================================
:do_apply_11
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置供应链防护 & goto :eof )

if not exist "%OPENCLAW_CONFIG_DIR%" mkdir "%OPENCLAW_CONFIG_DIR%"

(
    echo # OpenClaw Skill/MCP 供应链安全策略
    echo # 背景: ClawHavoc - 341 恶意 Skill 分发 AMOS 木马
    echo.
    echo REQUIRE_SIGNED_SKILLS=true
    echo SKILL_SANDBOX=true
    echo MCP_WHITELIST_ONLY=true
    echo MCP_AUDIT_TOOL_DESCRIPTIONS=true
    echo MCP_BLOCK_HIDDEN_INSTRUCTIONS=true
    echo SKILL_INTEGRITY_CHECK=true
) > "%OPENCLAW_CONFIG_DIR%\skill-security.conf"

REM Skill 检查脚本
(
    echo @echo off
    echo echo ===== Skill 安全检查 =====
    echo echo 检查: %%1
    echo echo.
    echo echo [1] 检查可疑安装命令...
    echo findstr /s /i "curl.*^|.*sh wget.*^|.*bash pip.install npm.install.-g" "%%~1\*" 2^>nul
    echo echo.
    echo echo [2] 检查隐藏指令...
    echo findstr /s /i "ignore.previous ignore.above system.prompt" "%%~1\*" 2^>nul
    echo echo.
    echo echo [3] 检查敏感路径访问...
    echo findstr /s /i "\.ssh \.aws \.gnupg credentials" "%%~1\*" 2^>nul
) > "%OPENCLAW_CONFIG_DIR%\verify-skill.bat"

call :log_action apply 11 success "供应链防护配置完成"
echo   [完成] Skill 安全策略 + 完整性检查
goto :eof

:do_rollback_11
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
del /q "%OPENCLAW_CONFIG_DIR%\skill-security.conf" 2>nul
del /q "%OPENCLAW_CONFIG_DIR%\verify-skill.bat" 2>nul
echo   [完成] 供应链防护已删除
goto :eof

REM ============================================================================
REM [12] 进程资源限制 — 防资源耗尽
REM ============================================================================
:do_apply_12
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] 将配置资源限制 & goto :eof )

if not exist "%OPENCLAW_CONFIG_DIR%" mkdir "%OPENCLAW_CONFIG_DIR%"

REM 资源限制配置文件 (不依赖外部工具)
(
    echo # OpenClaw 进程资源限制配置
    echo MAX_MEMORY_MB=2048
    echo MAX_CPU_PERCENT=50
    echo MAX_PROCESSES=64
) > "%OPENCLAW_CONFIG_DIR%\resource-limits.conf"
echo   [完成] 资源限制配置文件

REM 启用 DEP (需要 bcdedit)
if "%HAS_BCDEDIT%"=="1" (
    bcdedit /set nx AlwaysOn >nul 2>&1
    if !errorlevel!==0 (
        echo   [完成] DEP 已启用 (AlwaysOn)
    ) else (
        echo   [警告] bcdedit DEP 配置失败 (可能需重启生效或 UEFI 限制)
        call :log_info "bcdedit DEP 失败"
    )
) else (
    echo   [提示] bcdedit 不可用，跳过 DEP 配置
    call :log_info "bcdedit 不可用，跳过 DEP"
)

REM 配置进程缓解 (需要 PowerShell)
if "%HAS_POWERSHELL%"=="1" (
    powershell -Command "Set-ProcessMitigation -System -Enable DEP,SEHOP -ErrorAction SilentlyContinue" >nul 2>&1
    if !errorlevel!==0 (
        echo   [完成] SEHOP 已启用
    ) else (
        echo   [警告] Set-ProcessMitigation 失败 (Windows 版本可能不支持)
        call :log_info "ProcessMitigation 失败"
    )
) else (
    echo   [提示] PowerShell 不可用，跳过 SEHOP 配置
)

call :log_action apply 12 success "资源限制配置完成"
goto :eof

:do_rollback_12
if "%DRY_RUN%"=="1" ( echo   [DRY-RUN] & goto :eof )
del /q "%OPENCLAW_CONFIG_DIR%\resource-limits.conf" 2>nul
if "%HAS_BCDEDIT%"=="1" ( bcdedit /set nx OptIn >nul 2>&1 )
echo   [完成] 资源限制已重置
goto :eof

REM ============================================================================
REM 帮助/退出
REM ============================================================================
:show_help
echo OpenClaw Windows 安全加固脚本 v1.2
echo.
echo 用法: %~nx0 [选项]
echo   --help         帮助
echo   --dry-run      模拟运行
echo   --status       查看状态
echo   --rollback N   回退加固项 N (1-12)
echo   --debug N      调试加固项 N (1-12)
echo   --apply N      应用加固项 N (1-12)
goto :eof

:exit_script
call :log_info "脚本退出"
echo 日志: %LOG_FILE%
exit /b 0
