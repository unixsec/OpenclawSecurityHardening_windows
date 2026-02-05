@echo off
REM ============================================================================
REM OpenClaw Windows 10 交互式安全加固脚本
REM 版本: 2.0
REM 作者: Alex
REM 邮箱: unix_sec@163.com
REM 适用: Windows 10 / Windows Server 2016+
REM 
REM 功能:
REM   1. 创建专用服务账户
REM   2. 配置文件系统权限 (NTFS ACL)
REM   3. 配置 Windows 防火墙
REM   4. 配置 Windows Defender
REM   5. 启用安全审计策略
REM   6. 生成安全配置文件
REM   7. 安装 OpenClaw 服务
REM
REM 使用方法: 以管理员身份运行此脚本
REM ============================================================================

setlocal EnableDelayedExpansion

REM ============================================================================
REM 配置变量 - 根据实际环境修改
REM ============================================================================
set "OPENCLAW_DIR=C:\OpenClaw"
set "OPENCLAW_STATE_DIR=%USERPROFILE%\.openclaw"
set "OPENCLAW_LOGS_DIR=C:\Logs\OpenClaw"
set "OPENCLAW_SECRETS_DIR=%OPENCLAW_DIR%\secrets"
set "SERVICE_ACCOUNT=openclaw_svc"
set "GATEWAY_PORT=18789"
set "NODE_PATH=C:\Program Files\nodejs"
set "LOG_FILE=%TEMP%\openclaw-hardening-%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%-%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.log"
set "LOG_FILE=%LOG_FILE: =0%"

REM 颜色代码
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"
set "BOLD=[1m"

REM 加固项选择状态 (0=未选, 1=已选)
set "SEL_1=0"
set "SEL_2=0"
set "SEL_3=0"
set "SEL_4=0"
set "SEL_5=0"
set "SEL_6=0"
set "SEL_7=0"

REM 加固项名称
set "NAME_1=创建服务账户"
set "NAME_2=配置文件权限"
set "NAME_3=配置防火墙"
set "NAME_4=配置 Windows Defender"
set "NAME_5=启用审计策略"
set "NAME_6=生成安全配置"
set "NAME_7=安装服务"

REM ============================================================================
REM 主程序入口
REM ============================================================================
:MAIN
cls
echo %CYAN%============================================================================%RESET%
echo %CYAN%        OpenClaw Windows 10 交互式安全加固脚本 v2.0%RESET%
echo %CYAN%        作者: Alex (unix_sec@163.com)%RESET%
echo %CYAN%============================================================================%RESET%
echo.

REM 检查是否为模拟运行模式
if /i "%~1"=="--dry-run" (
    set "DRY_RUN=1"
    echo %YELLOW%============================================%RESET%
    echo %YELLOW%  [模拟运行模式] 不会实际执行任何操作%RESET%
    echo %YELLOW%============================================%RESET%
    echo.
) else (
    set "DRY_RUN=0"
)

echo %YELLOW%警告: 此脚本将修改系统安全配置，请确保已备份重要数据！%RESET%
echo.
echo 日志文件: %LOG_FILE%
echo.

REM 检查管理员权限（模拟运行模式跳过）
if "%DRY_RUN%"=="0" (
    call :CHECK_ADMIN
    if !ERRORLEVEL! neq 0 (
        echo %RED%[错误] 请以管理员身份运行此脚本！%RESET%
        echo.
        pause
        exit /b 1
    )
)

REM 初始化日志
call :LOG "=========================================="
call :LOG "OpenClaw 安全加固开始 - %DATE% %TIME%"
call :LOG "=========================================="

REM 显示主菜单
:MAIN_MENU
cls
echo %CYAN%============================================================================%RESET%
echo %CYAN%        OpenClaw Windows 10 交互式安全加固脚本 v2.0%RESET%
echo %CYAN%============================================================================%RESET%
if "%DRY_RUN%"=="1" (
    echo %YELLOW%                    [模拟运行模式]%RESET%
)
echo.
echo %WHITE%请选择操作模式:%RESET%
echo.
echo   %CYAN%[1]%RESET% 交互式选择加固项 (推荐)
echo   %CYAN%[2]%RESET% 一键完整加固 (执行所有加固项)
echo   %CYAN%[3]%RESET% 生成安全审计报告
echo   %CYAN%[4]%RESET% 撤销安全加固 (紧急恢复)
echo   %CYAN%[0]%RESET% 退出
echo.
set /p MAIN_CHOICE="请输入选项 [0-4]: "

if "%MAIN_CHOICE%"=="1" goto SELECT_ITEMS
if "%MAIN_CHOICE%"=="2" goto ONE_CLICK_ALL
if "%MAIN_CHOICE%"=="3" goto SECURITY_AUDIT
if "%MAIN_CHOICE%"=="4" goto ROLLBACK
if "%MAIN_CHOICE%"=="0" goto EXIT
echo %RED%无效选项，请重新输入%RESET%
timeout /t 1 >nul
goto MAIN_MENU

REM ============================================================================
REM 交互式选择加固项
REM ============================================================================
:SELECT_ITEMS
cls
echo %CYAN%============================================================================%RESET%
echo %CYAN%                    选择要执行的安全加固项%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo %WHITE%输入数字切换选中状态，输入 A 全选，输入 N 全不选%RESET%
echo %WHITE%选择完毕后输入 E 执行，输入 B 返回主菜单%RESET%
echo.
echo %CYAN%============================================================================%RESET%
echo.

REM 显示选择状态
call :SHOW_ITEM 1
call :SHOW_ITEM 2
call :SHOW_ITEM 3
call :SHOW_ITEM 4
call :SHOW_ITEM 5
call :SHOW_ITEM 6
call :SHOW_ITEM 7

echo.
echo %CYAN%============================================================================%RESET%
echo.
echo   %CYAN%[A]%RESET% 全选所有加固项
echo   %CYAN%[N]%RESET% 取消全部选择
echo   %CYAN%[E]%RESET% 执行选中的加固项
echo   %CYAN%[B]%RESET% 返回主菜单
echo.

set /p SEL_CHOICE="请输入选项: "

REM 处理输入
if /i "%SEL_CHOICE%"=="A" (
    set "SEL_1=1"
    set "SEL_2=1"
    set "SEL_3=1"
    set "SEL_4=1"
    set "SEL_5=1"
    set "SEL_6=1"
    set "SEL_7=1"
    goto SELECT_ITEMS
)

if /i "%SEL_CHOICE%"=="N" (
    set "SEL_1=0"
    set "SEL_2=0"
    set "SEL_3=0"
    set "SEL_4=0"
    set "SEL_5=0"
    set "SEL_6=0"
    set "SEL_7=0"
    goto SELECT_ITEMS
)

if /i "%SEL_CHOICE%"=="E" goto EXECUTE_SELECTED
if /i "%SEL_CHOICE%"=="B" goto MAIN_MENU

REM 切换单个选项状态
if "%SEL_CHOICE%"=="1" (
    if "!SEL_1!"=="0" (set "SEL_1=1") else (set "SEL_1=0")
    goto SELECT_ITEMS
)
if "%SEL_CHOICE%"=="2" (
    if "!SEL_2!"=="0" (set "SEL_2=1") else (set "SEL_2=0")
    goto SELECT_ITEMS
)
if "%SEL_CHOICE%"=="3" (
    if "!SEL_3!"=="0" (set "SEL_3=1") else (set "SEL_3=0")
    goto SELECT_ITEMS
)
if "%SEL_CHOICE%"=="4" (
    if "!SEL_4!"=="0" (set "SEL_4=1") else (set "SEL_4=0")
    goto SELECT_ITEMS
)
if "%SEL_CHOICE%"=="5" (
    if "!SEL_5!"=="0" (set "SEL_5=1") else (set "SEL_5=0")
    goto SELECT_ITEMS
)
if "%SEL_CHOICE%"=="6" (
    if "!SEL_6!"=="0" (set "SEL_6=1") else (set "SEL_6=0")
    goto SELECT_ITEMS
)
if "%SEL_CHOICE%"=="7" (
    if "!SEL_7!"=="0" (set "SEL_7=1") else (set "SEL_7=0")
    goto SELECT_ITEMS
)

REM 支持多选 (如输入 123 选择 1、2、3)
set "INPUT=%SEL_CHOICE%"
:PARSE_INPUT
if "%INPUT%"=="" goto SELECT_ITEMS
set "CHAR=%INPUT:~0,1%"
set "INPUT=%INPUT:~1%"

if "%CHAR%"=="1" (if "!SEL_1!"=="0" (set "SEL_1=1") else (set "SEL_1=0"))
if "%CHAR%"=="2" (if "!SEL_2!"=="0" (set "SEL_2=1") else (set "SEL_2=0"))
if "%CHAR%"=="3" (if "!SEL_3!"=="0" (set "SEL_3=1") else (set "SEL_3=0"))
if "%CHAR%"=="4" (if "!SEL_4!"=="0" (set "SEL_4=1") else (set "SEL_4=0"))
if "%CHAR%"=="5" (if "!SEL_5!"=="0" (set "SEL_5=1") else (set "SEL_5=0"))
if "%CHAR%"=="6" (if "!SEL_6!"=="0" (set "SEL_6=1") else (set "SEL_6=0"))
if "%CHAR%"=="7" (if "!SEL_7!"=="0" (set "SEL_7=1") else (set "SEL_7=0"))

goto PARSE_INPUT

REM ============================================================================
REM 显示单个选项
REM ============================================================================
:SHOW_ITEM
set "ITEM_NUM=%1"
set "ITEM_SEL=!SEL_%ITEM_NUM%!"
set "ITEM_NAME=!NAME_%ITEM_NUM%!"

if "%ITEM_SEL%"=="1" (
    echo   %GREEN%[√] [%ITEM_NUM%] %ITEM_NAME%%RESET%
) else (
    echo   %WHITE%[ ] [%ITEM_NUM%] %ITEM_NAME%%RESET%
)
goto :EOF

REM ============================================================================
REM 执行选中的加固项
REM ============================================================================
:EXECUTE_SELECTED
REM 检查是否有选中项
set "SELECTED_COUNT=0"
if "%SEL_1%"=="1" set /a SELECTED_COUNT+=1
if "%SEL_2%"=="1" set /a SELECTED_COUNT+=1
if "%SEL_3%"=="1" set /a SELECTED_COUNT+=1
if "%SEL_4%"=="1" set /a SELECTED_COUNT+=1
if "%SEL_5%"=="1" set /a SELECTED_COUNT+=1
if "%SEL_6%"=="1" set /a SELECTED_COUNT+=1
if "%SEL_7%"=="1" set /a SELECTED_COUNT+=1

if %SELECTED_COUNT% equ 0 (
    echo.
    echo %YELLOW%请至少选择一个加固项！%RESET%
    timeout /t 2 >nul
    goto SELECT_ITEMS
)

cls
echo %CYAN%============================================================================%RESET%
echo %CYAN%                        确认执行以下加固项%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo %WHITE%已选择 %SELECTED_COUNT% 个加固项:%RESET%
echo.

if "%SEL_1%"=="1" echo   %GREEN%[√]%RESET% %NAME_1%
if "%SEL_2%"=="1" echo   %GREEN%[√]%RESET% %NAME_2%
if "%SEL_3%"=="1" echo   %GREEN%[√]%RESET% %NAME_3%
if "%SEL_4%"=="1" echo   %GREEN%[√]%RESET% %NAME_4%
if "%SEL_5%"=="1" echo   %GREEN%[√]%RESET% %NAME_5%
if "%SEL_6%"=="1" echo   %GREEN%[√]%RESET% %NAME_6%
if "%SEL_7%"=="1" echo   %GREEN%[√]%RESET% %NAME_7%

echo.
echo %CYAN%============================================================================%RESET%
echo.
set /p CONFIRM="确认执行以上加固项? [Y/N]: "
if /i not "%CONFIRM%"=="Y" goto SELECT_ITEMS

call :LOG "用户选择执行加固项: SEL_1=%SEL_1%, SEL_2=%SEL_2%, SEL_3=%SEL_3%, SEL_4=%SEL_4%, SEL_5=%SEL_5%, SEL_6=%SEL_6%, SEL_7=%SEL_7%"

REM 开始执行
cls
echo %CYAN%============================================================================%RESET%
echo %CYAN%                        开始执行安全加固%RESET%
echo %CYAN%============================================================================%RESET%
echo.

set "STEP=0"
set "TOTAL=%SELECTED_COUNT%"

REM 首先创建目录结构（如果需要）
if "%SEL_1%"=="1" call :CREATE_DIRECTORIES
if "%SEL_2%"=="1" call :CREATE_DIRECTORIES
if "%SEL_6%"=="1" call :CREATE_DIRECTORIES
if "%SEL_7%"=="1" call :CREATE_DIRECTORIES

REM 执行选中的加固项
if "%SEL_1%"=="1" (
    set /a STEP+=1
    echo.
    echo %CYAN%[!STEP!/%TOTAL%] 正在执行: %NAME_1%%RESET%
    call :DO_CREATE_SERVICE_ACCOUNT
)

if "%SEL_2%"=="1" (
    set /a STEP+=1
    echo.
    echo %CYAN%[!STEP!/%TOTAL%] 正在执行: %NAME_2%%RESET%
    call :DO_CONFIGURE_PERMISSIONS
)

if "%SEL_3%"=="1" (
    set /a STEP+=1
    echo.
    echo %CYAN%[!STEP!/%TOTAL%] 正在执行: %NAME_3%%RESET%
    call :DO_CONFIGURE_FIREWALL
)

if "%SEL_4%"=="1" (
    set /a STEP+=1
    echo.
    echo %CYAN%[!STEP!/%TOTAL%] 正在执行: %NAME_4%%RESET%
    call :DO_CONFIGURE_DEFENDER
)

if "%SEL_5%"=="1" (
    set /a STEP+=1
    echo.
    echo %CYAN%[!STEP!/%TOTAL%] 正在执行: %NAME_5%%RESET%
    call :DO_CONFIGURE_AUDIT
)

if "%SEL_6%"=="1" (
    set /a STEP+=1
    echo.
    echo %CYAN%[!STEP!/%TOTAL%] 正在执行: %NAME_6%%RESET%
    call :DO_GENERATE_SECURE_CONFIG
)

if "%SEL_7%"=="1" (
    set /a STEP+=1
    echo.
    echo %CYAN%[!STEP!/%TOTAL%] 正在执行: %NAME_7%%RESET%
    call :DO_INSTALL_SERVICE
)

echo.
echo %GREEN%============================================================================%RESET%
echo %GREEN%              安全加固完成！共执行 %SELECTED_COUNT% 个加固项%RESET%
echo %GREEN%============================================================================%RESET%
echo.
echo %YELLOW%重要提示:%RESET%
if "%SEL_1%"=="1" (
    echo   - 请设置服务账户密码: net user %SERVICE_ACCOUNT% *
)
if "%SEL_6%"=="1" (
    echo   - Gateway Token 保存在: %OPENCLAW_SECRETS_DIR%\gateway-token.txt
)
echo   - 详细日志: %LOG_FILE%
echo.

call :LOG "安全加固完成，共执行 %SELECTED_COUNT% 个加固项"
pause
goto MAIN_MENU

REM ============================================================================
REM 一键完整加固
REM ============================================================================
:ONE_CLICK_ALL
cls
echo %CYAN%============================================================================%RESET%
echo %CYAN%                        一键完整安全加固%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo %WHITE%将执行以下所有安全加固项:%RESET%
echo.
echo   %GREEN%[√]%RESET% %NAME_1%
echo   %GREEN%[√]%RESET% %NAME_2%
echo   %GREEN%[√]%RESET% %NAME_3%
echo   %GREEN%[√]%RESET% %NAME_4%
echo   %GREEN%[√]%RESET% %NAME_5%
echo   %GREEN%[√]%RESET% %NAME_6%
echo   %GREEN%[√]%RESET% %NAME_7%
echo.
echo %CYAN%============================================================================%RESET%
echo.
echo %YELLOW%警告: 此操作将执行所有安全加固措施！%RESET%
echo.
set /p CONFIRM="确认执行完整安全加固? [Y/N]: "
if /i not "%CONFIRM%"=="Y" goto MAIN_MENU

REM 设置全选
set "SEL_1=1"
set "SEL_2=1"
set "SEL_3=1"
set "SEL_4=1"
set "SEL_5=1"
set "SEL_6=1"
set "SEL_7=1"

call :LOG "用户选择一键完整加固"
goto EXECUTE_SELECTED

REM ============================================================================
REM 创建目录结构
REM ============================================================================
:CREATE_DIRECTORIES
if "%DIRS_CREATED%"=="1" goto :EOF
set "DIRS_CREATED=1"

echo   创建目录结构...
call :LOG "创建目录结构"

if not exist "%OPENCLAW_DIR%" (
    mkdir "%OPENCLAW_DIR%"
    echo     创建: %OPENCLAW_DIR%
)

if not exist "%OPENCLAW_STATE_DIR%" (
    mkdir "%OPENCLAW_STATE_DIR%"
    echo     创建: %OPENCLAW_STATE_DIR%
)

if not exist "%OPENCLAW_LOGS_DIR%" (
    mkdir "%OPENCLAW_LOGS_DIR%"
    echo     创建: %OPENCLAW_LOGS_DIR%
)

if not exist "%OPENCLAW_SECRETS_DIR%" (
    mkdir "%OPENCLAW_SECRETS_DIR%"
    echo     创建: %OPENCLAW_SECRETS_DIR%
)

echo   %GREEN%[完成] 目录结构已创建%RESET%
goto :EOF

REM ============================================================================
REM 创建服务账户
REM ============================================================================
:DO_CREATE_SERVICE_ACCOUNT
call :LOG "创建服务账户: %SERVICE_ACCOUNT%"

REM 模拟运行模式
if "%DRY_RUN%"=="1" (
    echo   %CYAN%[DRY-RUN] 将执行以下操作:%RESET%
    echo     - net user %SERVICE_ACCOUNT% [PASSWORD] /add
    echo     - net localgroup Administrators %SERVICE_ACCOUNT% /delete
    echo     - net localgroup Users %SERVICE_ACCOUNT% /delete
    echo     - secedit /export /cfg secpol_export.cfg
    echo     - secedit /configure /db secedit.sdb /cfg secpol_import.cfg /areas USER_RIGHTS
    echo   %GREEN%[DRY-RUN 完成] 服务账户配置%RESET%
    goto :EOF
)

REM 检查账户是否已存在
net user %SERVICE_ACCOUNT% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   %YELLOW%[跳过] 服务账户 %SERVICE_ACCOUNT% 已存在%RESET%
    call :LOG "服务账户已存在，跳过创建"
    goto :CONFIGURE_SVC_ACCOUNT
)

REM 生成随机密码
set "CHARS=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$"
set "PASSWORD="
for /L %%i in (1,1,16) do (
    set /a "rand=!random! %% 68"
    for %%j in (!rand!) do set "PASSWORD=!PASSWORD!!CHARS:~%%j,1!"
)

REM 创建用户账户
net user %SERVICE_ACCOUNT% "%PASSWORD%" /add /comment:"OpenClaw Service Account" /fullname:"OpenClaw Service" /passwordchg:no >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   %RED%[失败] 无法创建服务账户%RESET%
    call :LOG "错误: 无法创建服务账户"
    goto :EOF
)

echo   账户 %SERVICE_ACCOUNT% 已创建
echo   %YELLOW%临时密码: %PASSWORD%%RESET%
echo   %YELLOW%请立即更改密码: net user %SERVICE_ACCOUNT% *%RESET%

REM 保存密码到临时文件
echo %PASSWORD%> "%TEMP%\openclaw_svc_password.txt"
echo   %YELLOW%密码已保存到: %TEMP%\openclaw_svc_password.txt (请立即保存并删除)%RESET%

:CONFIGURE_SVC_ACCOUNT
REM 从管理员组中移除（如果存在）
net localgroup Administrators %SERVICE_ACCOUNT% /delete >nul 2>&1

REM 从 Users 组中移除（减少权限）
net localgroup Users %SERVICE_ACCOUNT% /delete >nul 2>&1

REM 配置服务登录权限
echo   配置账户安全策略...

REM 导出当前策略
secedit /export /cfg "%TEMP%\secpol_export.cfg" >nul 2>&1

REM 检查并添加服务登录权限
findstr /C:"SeServiceLogonRight" "%TEMP%\secpol_export.cfg" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    powershell -Command "(Get-Content '%TEMP%\secpol_export.cfg') -replace 'SeServiceLogonRight = ', 'SeServiceLogonRight = %SERVICE_ACCOUNT%,' | Set-Content '%TEMP%\secpol_import.cfg'" >nul 2>&1
    secedit /configure /db secedit.sdb /cfg "%TEMP%\secpol_import.cfg" /areas USER_RIGHTS >nul 2>&1
)

echo   %GREEN%[完成] 服务账户配置完成%RESET%
call :LOG "服务账户配置完成"
goto :EOF

REM ============================================================================
REM 配置文件权限
REM ============================================================================
:DO_CONFIGURE_PERMISSIONS
call :LOG "配置文件系统权限"

REM 模拟运行模式
if "%DRY_RUN%"=="1" (
    echo   %CYAN%[DRY-RUN] 将执行以下操作:%RESET%
    echo     - icacls %OPENCLAW_DIR% /inheritance:r
    echo     - icacls %OPENCLAW_DIR% /grant:r "SYSTEM:(OI)(CI)F"
    echo     - icacls %OPENCLAW_DIR% /grant:r "Administrators:(OI)(CI)F"
    echo     - icacls %OPENCLAW_DIR% /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)RX"
    echo     - icacls %OPENCLAW_STATE_DIR% /inheritance:r ...
    echo     - icacls %OPENCLAW_SECRETS_DIR% /inheritance:r ...
    echo     - icacls %OPENCLAW_LOGS_DIR% /inheritance:r ...
    echo   %GREEN%[DRY-RUN 完成] 文件权限配置%RESET%
    goto :EOF
)

REM 配置 OpenClaw 主目录
echo   配置 %OPENCLAW_DIR% 权限...
icacls "%OPENCLAW_DIR%" /inheritance:r >nul 2>&1
icacls "%OPENCLAW_DIR%" /grant:r "SYSTEM:(OI)(CI)F" >nul 2>&1
icacls "%OPENCLAW_DIR%" /grant:r "BUILTIN\Administrators:(OI)(CI)F" >nul 2>&1
icacls "%OPENCLAW_DIR%" /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)RX" >nul 2>&1

REM 配置状态目录
echo   配置 %OPENCLAW_STATE_DIR% 权限...
icacls "%OPENCLAW_STATE_DIR%" /inheritance:r >nul 2>&1
icacls "%OPENCLAW_STATE_DIR%" /grant:r "SYSTEM:(OI)(CI)F" >nul 2>&1
icacls "%OPENCLAW_STATE_DIR%" /grant:r "BUILTIN\Administrators:(OI)(CI)F" >nul 2>&1
icacls "%OPENCLAW_STATE_DIR%" /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)M" >nul 2>&1
icacls "%OPENCLAW_STATE_DIR%" /grant:r "%USERNAME%:(OI)(CI)F" >nul 2>&1

REM 配置密钥目录（最严格权限）
echo   配置 %OPENCLAW_SECRETS_DIR% 权限...
icacls "%OPENCLAW_SECRETS_DIR%" /inheritance:r >nul 2>&1
icacls "%OPENCLAW_SECRETS_DIR%" /grant:r "SYSTEM:(OI)(CI)F" >nul 2>&1
icacls "%OPENCLAW_SECRETS_DIR%" /grant:r "BUILTIN\Administrators:(OI)(CI)F" >nul 2>&1
icacls "%OPENCLAW_SECRETS_DIR%" /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)R" >nul 2>&1

REM 配置日志目录
echo   配置 %OPENCLAW_LOGS_DIR% 权限...
icacls "%OPENCLAW_LOGS_DIR%" /inheritance:r >nul 2>&1
icacls "%OPENCLAW_LOGS_DIR%" /grant:r "SYSTEM:(OI)(CI)F" >nul 2>&1
icacls "%OPENCLAW_LOGS_DIR%" /grant:r "BUILTIN\Administrators:(OI)(CI)F" >nul 2>&1
icacls "%OPENCLAW_LOGS_DIR%" /grant:r "%SERVICE_ACCOUNT%:(OI)(CI)M" >nul 2>&1

REM 如果配置文件存在，设置更严格的权限
if exist "%OPENCLAW_STATE_DIR%\config.yaml" (
    echo   配置 config.yaml 权限...
    icacls "%OPENCLAW_STATE_DIR%\config.yaml" /inheritance:r >nul 2>&1
    icacls "%OPENCLAW_STATE_DIR%\config.yaml" /grant:r "SYSTEM:F" >nul 2>&1
    icacls "%OPENCLAW_STATE_DIR%\config.yaml" /grant:r "BUILTIN\Administrators:F" >nul 2>&1
    icacls "%OPENCLAW_STATE_DIR%\config.yaml" /grant:r "%SERVICE_ACCOUNT%:R" >nul 2>&1
    icacls "%OPENCLAW_STATE_DIR%\config.yaml" /grant:r "%USERNAME%:F" >nul 2>&1
)

echo   %GREEN%[完成] 文件系统权限配置完成%RESET%
call :LOG "文件系统权限配置完成"
goto :EOF

REM ============================================================================
REM 配置防火墙
REM ============================================================================
:DO_CONFIGURE_FIREWALL
call :LOG "配置 Windows 防火墙"

REM 模拟运行模式
if "%DRY_RUN%"=="1" (
    echo   %CYAN%[DRY-RUN] 将执行以下操作:%RESET%
    echo     - netsh advfirewall set allprofiles state on
    echo     - netsh advfirewall firewall delete rule name="OpenClaw*"
    echo     - netsh advfirewall firewall add rule name="OpenClaw Gateway - Block All Inbound" ...
    echo     - netsh advfirewall firewall add rule name="OpenClaw Gateway - Allow Loopback" ...
    echo     - netsh advfirewall firewall add rule name="OpenClaw - Allow HTTPS Outbound" ...
    echo     - netsh advfirewall set allprofiles logging ...
    echo   %GREEN%[DRY-RUN 完成] 防火墙配置%RESET%
    goto :EOF
)

REM 启用防火墙
echo   启用 Windows 防火墙...
netsh advfirewall set allprofiles state on >nul 2>&1

REM 删除旧规则
echo   删除旧的 OpenClaw 防火墙规则...
netsh advfirewall firewall delete rule name="OpenClaw*" >nul 2>&1

REM 阻止所有入站连接到 Gateway 端口
echo   阻止 Gateway 端口 (%GATEWAY_PORT%) 外部访问...
netsh advfirewall firewall add rule name="OpenClaw Gateway - Block All Inbound" ^
    dir=in action=block protocol=TCP localport=%GATEWAY_PORT% >nul 2>&1

REM 允许本地回环访问
echo   允许本地回环访问...
netsh advfirewall firewall add rule name="OpenClaw Gateway - Allow Loopback" ^
    dir=in action=allow protocol=TCP localport=%GATEWAY_PORT% ^
    remoteip=127.0.0.1 localip=127.0.0.1 >nul 2>&1

REM 配置出站规则
echo   配置出站规则...
netsh advfirewall firewall add rule name="OpenClaw - Allow HTTPS Outbound" ^
    dir=out action=allow protocol=TCP remoteport=443 ^
    program="%NODE_PATH%\node.exe" >nul 2>&1

REM 启用防火墙日志
echo   启用防火墙日志...
netsh advfirewall set allprofiles logging filename="%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" >nul 2>&1
netsh advfirewall set allprofiles logging maxfilesize=32768 >nul 2>&1
netsh advfirewall set allprofiles logging droppedconnections=enable >nul 2>&1
netsh advfirewall set allprofiles logging allowedconnections=disable >nul 2>&1

echo   %GREEN%[完成] Windows 防火墙配置完成%RESET%
call :LOG "Windows 防火墙配置完成"
goto :EOF

REM ============================================================================
REM 配置 Windows Defender
REM ============================================================================
:DO_CONFIGURE_DEFENDER
call :LOG "配置 Windows Defender"

REM 模拟运行模式
if "%DRY_RUN%"=="1" (
    echo   %CYAN%[DRY-RUN] 将执行以下操作:%RESET%
    echo     - Set-MpPreference -DisableRealtimeMonitoring $false
    echo     - Set-MpPreference -DisableBehaviorMonitoring $false
    echo     - Set-MpPreference -DisableScriptScanning $false
    echo     - Set-MpPreference -MAPSReporting Advanced
    echo     - Add-MpPreference -AttackSurfaceReductionRules_Ids ...
    echo     - Set-MpPreference -ScanScheduleQuickScanTime 02:00:00
    echo   %GREEN%[DRY-RUN 完成] Windows Defender 配置%RESET%
    goto :EOF
)

REM 检查 Windows Defender 是否可用
sc query WinDefend >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   %YELLOW%[跳过] Windows Defender 未安装或不可用%RESET%
    call :LOG "Windows Defender 不可用，跳过配置"
    goto :EOF
)

REM 使用 PowerShell 配置 Defender
echo   启用实时保护...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" >nul 2>&1

echo   启用行为监控...
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false" >nul 2>&1

echo   启用脚本扫描...
powershell -Command "Set-MpPreference -DisableScriptScanning $false" >nul 2>&1

echo   启用云保护...
powershell -Command "Set-MpPreference -MAPSReporting Advanced" >nul 2>&1
powershell -Command "Set-MpPreference -SubmitSamplesConsent SendSafeSamples" >nul 2>&1

echo   配置 ASR 规则 (攻击面缩减)...
REM 阻止可能被混淆的脚本执行
powershell -Command "Add-MpPreference -AttackSurfaceReductionRules_Ids 5BEB7EFE-FD9A-4556-801D-275E5FFC04CC -AttackSurfaceReductionRules_Actions Enabled" >nul 2>&1

REM 阻止从 Windows 本地安全子系统窃取凭据
powershell -Command "Add-MpPreference -AttackSurfaceReductionRules_Ids 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2 -AttackSurfaceReductionRules_Actions Enabled" >nul 2>&1

echo   配置扫描计划...
powershell -Command "Set-MpPreference -ScanScheduleQuickScanTime 02:00:00" >nul 2>&1

echo   %GREEN%[完成] Windows Defender 配置完成%RESET%
call :LOG "Windows Defender 配置完成"
goto :EOF

REM ============================================================================
REM 配置审计策略
REM ============================================================================
:DO_CONFIGURE_AUDIT
call :LOG "配置安全审计策略"

REM 模拟运行模式
if "%DRY_RUN%"=="1" (
    echo   %CYAN%[DRY-RUN] 将执行以下操作:%RESET%
    echo     - auditpol /set /subcategory:"Logon" /success:enable /failure:enable
    echo     - auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
    echo     - auditpol /set /subcategory:"File System" /success:enable /failure:enable
    echo     - auditpol /set /subcategory:"Other Object Access Events" ...
    echo     - auditpol /set /subcategory:"Sensitive Privilege Use" ...
    echo     - wevtutil sl Security /ms:524288000
    echo     - 配置目录审计规则
    echo   %GREEN%[DRY-RUN 完成] 审计策略配置%RESET%
    goto :EOF
)

REM 启用登录审计
echo   启用登录审计...
auditpol /set /subcategory:"Logon" /success:enable /failure:enable >nul 2>&1

REM 启用进程创建审计
echo   启用进程创建审计...
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable >nul 2>&1

REM 启用文件系统审计
echo   启用文件系统审计...
auditpol /set /subcategory:"File System" /success:enable /failure:enable >nul 2>&1

REM 启用对象访问审计
echo   启用对象访问审计...
auditpol /set /subcategory:"Other Object Access Events" /success:enable /failure:enable >nul 2>&1

REM 启用权限使用审计
echo   启用权限使用审计...
auditpol /set /subcategory:"Sensitive Privilege Use" /success:enable /failure:enable >nul 2>&1

REM 增加安全日志大小
echo   增加安全日志大小...
wevtutil sl Security /ms:524288000 >nul 2>&1

REM 配置 OpenClaw 目录审计
echo   配置 OpenClaw 目录文件审计...
if exist "%OPENCLAW_DIR%" (
    powershell -Command "$acl = Get-Acl '%OPENCLAW_DIR%'; $rule = New-Object System.Security.AccessControl.FileSystemAuditRule('Everyone','Delete,DeleteSubdirectoriesAndFiles,ChangePermissions,TakeOwnership','ContainerInherit,ObjectInherit','None','Failure'); $acl.AddAuditRule($rule); Set-Acl -Path '%OPENCLAW_DIR%' -AclObject $acl" >nul 2>&1
)

REM 配置 Secrets 目录审计（更严格）
echo   配置 Secrets 目录审计...
if exist "%OPENCLAW_SECRETS_DIR%" (
    powershell -Command "$acl = Get-Acl '%OPENCLAW_SECRETS_DIR%'; $rule = New-Object System.Security.AccessControl.FileSystemAuditRule('Everyone','Read,Write,Delete','ContainerInherit,ObjectInherit','None','Success,Failure'); $acl.AddAuditRule($rule); Set-Acl -Path '%OPENCLAW_SECRETS_DIR%' -AclObject $acl" >nul 2>&1
)

echo   %GREEN%[完成] 安全审计策略配置完成%RESET%
call :LOG "安全审计策略配置完成"
goto :EOF

REM ============================================================================
REM 生成安全配置文件
REM ============================================================================
:DO_GENERATE_SECURE_CONFIG
call :LOG "生成安全配置文件"

REM 模拟运行模式
if "%DRY_RUN%"=="1" (
    echo   %CYAN%[DRY-RUN] 将执行以下操作:%RESET%
    echo     - 生成随机 Gateway Token (32字符)
    echo     - 保存 Token 到 %OPENCLAW_SECRETS_DIR%\gateway-token.txt
    echo     - icacls gateway-token.txt /inheritance:r ...
    echo     - 创建 config.yaml 安全配置文件
    echo     - 创建 set-env.cmd 环境变量脚本
    echo   %GREEN%[DRY-RUN 完成] 安全配置生成%RESET%
    goto :EOF
)

REM 生成随机 Gateway Token
set "TOKEN_CHARS=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
set "GATEWAY_TOKEN="
for /L %%i in (1,1,32) do (
    set /a "rand=!random! %% 62"
    for %%j in (!rand!) do set "GATEWAY_TOKEN=!GATEWAY_TOKEN!!TOKEN_CHARS:~%%j,1!"
)

REM 保存 Gateway Token
echo %GATEWAY_TOKEN%> "%OPENCLAW_SECRETS_DIR%\gateway-token.txt"
echo   Gateway Token 已保存到: %OPENCLAW_SECRETS_DIR%\gateway-token.txt

REM 设置 Token 文件权限
icacls "%OPENCLAW_SECRETS_DIR%\gateway-token.txt" /inheritance:r >nul 2>&1
icacls "%OPENCLAW_SECRETS_DIR%\gateway-token.txt" /grant:r "SYSTEM:R" >nul 2>&1
icacls "%OPENCLAW_SECRETS_DIR%\gateway-token.txt" /grant:r "BUILTIN\Administrators:F" >nul 2>&1
icacls "%OPENCLAW_SECRETS_DIR%\gateway-token.txt" /grant:r "%SERVICE_ACCOUNT%:R" >nul 2>&1

REM 创建示例安全配置文件
if not exist "%OPENCLAW_STATE_DIR%\config.yaml" (
    echo # OpenClaw 安全配置 - 由安全加固脚本生成> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo # 生成时间: %DATE% %TIME%>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo # 作者: hejian/202412970>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo.>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo gateway:>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo   bind: loopback>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo   port: %GATEWAY_PORT%>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo   auth:>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo     mode: token>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo     # Token 从文件读取，不在配置中明文存储>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo   controlUi:>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo     enabled: true>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo     allowInsecureAuth: false>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo     dangerouslyDisableDeviceAuth: false>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo.>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo logging:>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo   redactSensitive: tools>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo.>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo tools:>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo   elevated:>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo     enabled: false>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo.>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo browser:>> "%OPENCLAW_STATE_DIR%\config.yaml"
    echo   enabled: false>> "%OPENCLAW_STATE_DIR%\config.yaml"
    
    echo   安全配置文件已创建: %OPENCLAW_STATE_DIR%\config.yaml
)

REM 创建环境变量设置脚本
echo @echo off> "%OPENCLAW_DIR%\set-env.cmd"
echo REM OpenClaw 环境变量设置>> "%OPENCLAW_DIR%\set-env.cmd"
echo REM 生成时间: %DATE% %TIME%>> "%OPENCLAW_DIR%\set-env.cmd"
echo set OPENCLAW_STATE_DIR=%OPENCLAW_STATE_DIR%>> "%OPENCLAW_DIR%\set-env.cmd"
echo set OPENCLAW_GATEWAY_TOKEN_FILE=%OPENCLAW_SECRETS_DIR%\gateway-token.txt>> "%OPENCLAW_DIR%\set-env.cmd"
echo set NODE_ENV=production>> "%OPENCLAW_DIR%\set-env.cmd"

echo   环境变量脚本已创建: %OPENCLAW_DIR%\set-env.cmd

echo   %GREEN%[完成] 安全配置文件生成完成%RESET%
call :LOG "安全配置文件生成完成"
goto :EOF

REM ============================================================================
REM 安装服务
REM ============================================================================
:DO_INSTALL_SERVICE
call :LOG "安装 OpenClaw 服务"

REM 模拟运行模式
if "%DRY_RUN%"=="1" (
    echo   %CYAN%[DRY-RUN] 将执行以下操作:%RESET%
    echo     - 检查 NSSM 和 Node.js
    echo     - nssm.exe install OpenClawGateway "%NODE_PATH%\node.exe"
    echo     - nssm.exe set OpenClawGateway AppParameters "%OPENCLAW_DIR%\dist\entry.js start"
    echo     - nssm.exe set OpenClawGateway ObjectName ".\%SERVICE_ACCOUNT%"
    echo     - 配置服务日志和环境变量
    echo     - sc failure OpenClawGateway reset= 86400 actions= restart/...
    echo   %GREEN%[DRY-RUN 完成] 服务安装%RESET%
    goto :EOF
)

REM 检查 NSSM
if not exist "C:\Tools\nssm.exe" (
    echo   %YELLOW%[警告] NSSM 未找到%RESET%
    echo   请下载 NSSM: https://nssm.cc/download
    echo   解压后将 nssm.exe 放到 C:\Tools\ 目录
    call :LOG "NSSM 未找到，跳过服务安装"
    goto :EOF
)

REM 检查 Node.js
if not exist "%NODE_PATH%\node.exe" (
    echo   %RED%[错误] Node.js 未找到: %NODE_PATH%\node.exe%RESET%
    call :LOG "Node.js 未找到，跳过服务安装"
    goto :EOF
)

REM 停止现有服务
net stop OpenClawGateway >nul 2>&1
C:\Tools\nssm.exe remove OpenClawGateway confirm >nul 2>&1

REM 安装服务
echo   安装 OpenClaw 服务...
C:\Tools\nssm.exe install OpenClawGateway "%NODE_PATH%\node.exe" >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway AppParameters "%OPENCLAW_DIR%\dist\entry.js start" >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway AppDirectory "%OPENCLAW_DIR%" >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway DisplayName "OpenClaw Gateway" >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway Description "OpenClaw AI Gateway Service" >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway Start SERVICE_AUTO_START >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway ObjectName ".\%SERVICE_ACCOUNT%" >nul 2>&1

REM 配置日志
C:\Tools\nssm.exe set OpenClawGateway AppStdout "%OPENCLAW_LOGS_DIR%\stdout.log" >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway AppStderr "%OPENCLAW_LOGS_DIR%\stderr.log" >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway AppStdoutCreationDisposition 4 >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway AppStderrCreationDisposition 4 >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway AppRotateFiles 1 >nul 2>&1
C:\Tools\nssm.exe set OpenClawGateway AppRotateBytes 10485760 >nul 2>&1

REM 配置环境变量
C:\Tools\nssm.exe set OpenClawGateway AppEnvironmentExtra ^
    "NODE_ENV=production" ^
    "OPENCLAW_STATE_DIR=%OPENCLAW_STATE_DIR%" ^
    "OPENCLAW_GATEWAY_TOKEN_FILE=%OPENCLAW_SECRETS_DIR%\gateway-token.txt" >nul 2>&1

REM 配置故障恢复
sc failure OpenClawGateway reset= 86400 actions= restart/5000/restart/10000/restart/30000 >nul 2>&1

echo   %GREEN%[完成] 服务已安装%RESET%
echo   %YELLOW%请设置服务账户密码后启动服务:%RESET%
echo     1. net user %SERVICE_ACCOUNT% *
echo     2. net start OpenClawGateway

call :LOG "OpenClaw 服务安装完成"
goto :EOF

REM ============================================================================
REM 安全审计报告
REM ============================================================================
:SECURITY_AUDIT
cls
echo %CYAN%============================================================================%RESET%
echo %CYAN%                    OpenClaw Windows 安全审计报告%RESET%
echo %CYAN%============================================================================%RESET%
echo 日期: %DATE% %TIME%
echo 作者: hejian/202412970
echo.

set "ISSUES=0"
set "WARNINGS=0"
set "PASSES=0"

REM 1. 检查服务账户
echo [1] 检查服务账户...
net user %SERVICE_ACCOUNT% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   %GREEN%[PASS] 服务账户 %SERVICE_ACCOUNT% 存在%RESET%
    set /a PASSES+=1
    
    REM 检查是否在管理员组
    net localgroup Administrators | findstr /i "%SERVICE_ACCOUNT%" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo   %RED%[FAIL] 服务账户在管理员组中！%RESET%
        set /a ISSUES+=1
    ) else (
        echo   %GREEN%[PASS] 服务账户不在管理员组中%RESET%
        set /a PASSES+=1
    )
) else (
    echo   %YELLOW%[WARN] 服务账户 %SERVICE_ACCOUNT% 不存在%RESET%
    set /a WARNINGS+=1
)

REM 2. 检查文件权限
echo.
echo [2] 检查文件权限...
if exist "%OPENCLAW_STATE_DIR%\config.yaml" (
    icacls "%OPENCLAW_STATE_DIR%\config.yaml" | findstr /i "Everyone Users" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo   %RED%[FAIL] config.yaml 对 Everyone/Users 可访问%RESET%
        set /a ISSUES+=1
    ) else (
        echo   %GREEN%[PASS] config.yaml 权限配置正确%RESET%
        set /a PASSES+=1
    )
) else (
    echo   %YELLOW%[WARN] config.yaml 不存在%RESET%
    set /a WARNINGS+=1
)

REM 3. 检查防火墙
echo.
echo [3] 检查防火墙...
netsh advfirewall show allprofiles | findstr /i "State.*ON" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   %GREEN%[PASS] Windows 防火墙已启用%RESET%
    set /a PASSES+=1
) else (
    echo   %RED%[FAIL] Windows 防火墙未启用%RESET%
    set /a ISSUES+=1
)

netsh advfirewall firewall show rule name="OpenClaw*" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   %GREEN%[PASS] OpenClaw 防火墙规则已配置%RESET%
    set /a PASSES+=1
) else (
    echo   %YELLOW%[WARN] OpenClaw 防火墙规则未配置%RESET%
    set /a WARNINGS+=1
)

REM 4. 检查端口暴露
echo.
echo [4] 检查端口暴露...
netstat -an | findstr ":%GATEWAY_PORT%.*LISTENING" | findstr /v "127.0.0.1" | findstr /v "\[::1\]" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   %RED%[FAIL] Gateway 端口对外暴露！%RESET%
    netstat -an | findstr ":%GATEWAY_PORT%.*LISTENING"
    set /a ISSUES+=1
) else (
    echo   %GREEN%[PASS] Gateway 端口未对外暴露%RESET%
    set /a PASSES+=1
)

REM 5. 检查 Windows Defender
echo.
echo [5] 检查 Windows Defender...
sc query WinDefend | findstr "RUNNING" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   %GREEN%[PASS] Windows Defender 正在运行%RESET%
    set /a PASSES+=1
    
    powershell -Command "(Get-MpComputerStatus).RealTimeProtectionEnabled" 2>nul | findstr "True" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo   %GREEN%[PASS] 实时保护已启用%RESET%
        set /a PASSES+=1
    ) else (
        echo   %RED%[FAIL] 实时保护未启用%RESET%
        set /a ISSUES+=1
    )
) else (
    echo   %YELLOW%[WARN] Windows Defender 未运行%RESET%
    set /a WARNINGS+=1
)

REM 6. 检查敏感数据
echo.
echo [6] 检查配置文件中的敏感数据...
if exist "%OPENCLAW_STATE_DIR%\config.yaml" (
    findstr /i "password.*:" "%OPENCLAW_STATE_DIR%\config.yaml" | findstr /v "#" | findstr /v "${" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo   %YELLOW%[WARN] 配置文件可能包含硬编码密码%RESET%
        set /a WARNINGS+=1
    ) else (
        echo   %GREEN%[PASS] 未发现硬编码密码%RESET%
        set /a PASSES+=1
    )
) else (
    echo   %YELLOW%[INFO] 配置文件不存在%RESET%
)

REM 7. 检查服务状态
echo.
echo [7] 检查服务状态...
sc query OpenClawGateway >nul 2>&1
if %ERRORLEVEL% equ 0 (
    sc query OpenClawGateway | findstr "RUNNING" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo   %GREEN%[INFO] OpenClaw 服务正在运行%RESET%
    ) else (
        echo   %YELLOW%[INFO] OpenClaw 服务未运行%RESET%
    )
    
    REM 检查服务账户
    for /f "tokens=2 delims=:" %%a in ('sc qc OpenClawGateway ^| findstr "SERVICE_START_NAME"') do (
        set "SVC_ACCOUNT=%%a"
        set "SVC_ACCOUNT=!SVC_ACCOUNT: =!"
        if /i "!SVC_ACCOUNT!"=="LocalSystem" (
            echo   %RED%[FAIL] 服务以 LocalSystem 运行 (权限过高)%RESET%
            set /a ISSUES+=1
        ) else (
            echo   %GREEN%[PASS] 服务账户: !SVC_ACCOUNT!%RESET%
            set /a PASSES+=1
        )
    )
) else (
    echo   %YELLOW%[INFO] OpenClaw 服务未安装%RESET%
)

REM 摘要
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN%                            审计摘要%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   %GREEN%通过: %PASSES% 项%RESET%
if %ISSUES% gtr 0 (
    echo   %RED%失败: %ISSUES% 项 (需要修复)%RESET%
) else (
    echo   %GREEN%失败: 0 项%RESET%
)
if %WARNINGS% gtr 0 (
    echo   %YELLOW%警告: %WARNINGS% 项 (建议关注)%RESET%
) else (
    echo   %GREEN%警告: 0 项%RESET%
)
echo.

if %ISSUES% gtr 0 (
    echo %RED%发现安全问题，建议执行安全加固！%RESET%
) else (
    echo %GREEN%安全状态良好%RESET%
)
echo.

call :LOG "安全审计完成: %PASSES% 通过, %ISSUES% 失败, %WARNINGS% 警告"
pause
goto MAIN_MENU

REM ============================================================================
REM 撤销安全加固（紧急恢复）
REM ============================================================================
:ROLLBACK
cls
echo %RED%============================================================================%RESET%
echo %RED%                        警告: 撤销安全加固%RESET%
echo %RED%============================================================================%RESET%
echo.
echo %WHITE%此操作将:%RESET%
echo.
echo   %RED%[1]%RESET% 删除 OpenClaw 防火墙规则
echo   %RED%[2]%RESET% 删除服务账户 %SERVICE_ACCOUNT%
echo   %RED%[3]%RESET% 重置文件权限（恢复继承）
echo   %RED%[4]%RESET% 停止并删除 OpenClaw 服务
echo.
echo %RED%============================================================================%RESET%
echo %RED%                        此操作不可逆！%RESET%
echo %RED%============================================================================%RESET%
echo.
set /p CONFIRM="确认撤销安全加固? 输入 CONFIRM 继续: "
if not "%CONFIRM%"=="CONFIRM" goto MAIN_MENU

call :LOG "开始撤销安全加固"

echo.
echo 正在撤销安全加固...
echo.

REM 停止并删除服务
echo   停止并删除服务...
net stop OpenClawGateway >nul 2>&1
sc delete OpenClawGateway >nul 2>&1

REM 删除防火墙规则
echo   删除防火墙规则...
netsh advfirewall firewall delete rule name="OpenClaw*" >nul 2>&1

REM 重置文件权限
echo   重置文件权限...
if exist "%OPENCLAW_DIR%" (
    icacls "%OPENCLAW_DIR%" /reset /t >nul 2>&1
)
if exist "%OPENCLAW_STATE_DIR%" (
    icacls "%OPENCLAW_STATE_DIR%" /reset /t >nul 2>&1
)

REM 删除服务账户
echo   删除服务账户...
net user %SERVICE_ACCOUNT% /delete >nul 2>&1

echo.
echo %GREEN%============================================================================%RESET%
echo %GREEN%                        安全加固已撤销%RESET%
echo %GREEN%============================================================================%RESET%
echo.
call :LOG "安全加固撤销完成"
pause
goto MAIN_MENU

REM ============================================================================
REM 工具函数
REM ============================================================================

:CHECK_ADMIN
net session >nul 2>&1
exit /b %ERRORLEVEL%

:LOG
echo [%DATE% %TIME%] %~1>> "%LOG_FILE%"
goto :EOF

REM ============================================================================
REM 执行命令（支持模拟运行模式）
REM ============================================================================
:EXEC
if "%DRY_RUN%"=="1" (
    echo   %CYAN%[DRY-RUN]%RESET% %~1
    goto :EOF
)
%~1
goto :EOF

:EXIT
echo.
echo 感谢使用 OpenClaw 安全加固脚本！
echo 作者: Alex (unix_sec@163.com)
call :LOG "脚本退出"
exit /b 0

REM ============================================================================
REM 脚本结束
REM ============================================================================
