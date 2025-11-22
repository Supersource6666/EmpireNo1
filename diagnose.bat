@echo off
REM P2P Chat Diagnostic Tool for Windows
REM 用于快速检查和诊断常见问题

setlocal enabledelayedexpansion
color 0A

echo =======================================
echo P2P 聊天系统诊断工具 (Windows 版)
echo =======================================
echo.

REM 获取用户输入
set /p SERVER_IP="请输入服务器 IP 地址 [默认: 192.168.1.102]: "
if "!SERVER_IP!"=="" set SERVER_IP=192.168.1.102

set /p SERVER_PORT="请输入服务器端口 [默认: 3000]: "
if "!SERVER_PORT!"=="" set SERVER_PORT=3000

echo.
echo 配置信息:
echo   服务器 IP: !SERVER_IP!
echo   服务器端口: !SERVER_PORT!
echo.

REM 1. 检查网络连接
echo [1/5] 检查网络连接...
ping -n 1 !SERVER_IP! >nul 2>&1
if !errorlevel! equ 0 (
    echo [成功] 网络连接正常
) else (
    echo [失败] 无法连接到服务器 IP: !SERVER_IP!
    echo.
    echo 建议:
    echo   - 检查设备是否连接到正确的网络
    echo   - 检查 IP 地址是否正确
    echo   - 检查防火墙设置
    echo.
)

REM 2. 检查端口
echo [2/5] 检查服务器端口...
netstat -ano | findstr /R ":!SERVER_PORT! " >nul 2>&1
if !errorlevel! equ 0 (
    echo [成功] 服务器端口 !SERVER_PORT! 已使用
) else (
    echo [失败] 无法找到监听端口 !SERVER_PORT!
    echo.
    echo 建议:
    echo   - 检查后端服务器是否运行
    echo   - 在服务器上执行: node server.js
    echo   - 检查防火墙是否允许该端口
    echo.
)

REM 3. 检查 REST API
echo [3/5] 检查 REST API...
for /f %%A in ('powershell -Command "try { (Invoke-WebRequest -Uri 'http://!SERVER_IP!:!SERVER_PORT!/api/health' -UseBasicParsing).StatusCode } catch { Write-Output '000' }"') do set HTTP_CODE=%%A

if "!HTTP_CODE!"=="200" (
    echo [成功] REST API 响应正常
) else (
    echo [失败] REST API 响应异常 (HTTP !HTTP_CODE!)
    echo.
    echo 建议:
    echo   - 检查后端服务器日志
    echo   - 确保 Express 服务器已启动
    echo.
)

REM 4. 显示本地网络信息
echo [4/5] 本地网络信息:
ipconfig | findstr "IPv4"
echo.

REM 5. 显示本地IP地址
echo [5/5] 获取本地 IP 地址...
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /R "IPv4.*192"') do (
    set LOCAL_IP=%%A
    goto found_ip
)
:found_ip
echo 本地 IP 地址: !LOCAL_IP!
echo.

REM 总结
echo =======================================
echo 诊断总结
echo =======================================
echo.
echo 如果连接失败，请按以下顺序检查:
echo.
echo 1. 确保后端服务器已启动:
echo    cd backend
echo    npm install
echo    node server.js
echo.
echo 2. 确认 IP 地址正确:
echo    在 config.dart 中设置: wsHost = '!SERVER_IP!'
echo.
echo 3. 检查防火墙设置:
echo    netsh advfirewall firewall add rule name="Allow Port !SERVER_PORT!" dir=in action=allow protocol=tcp localport=!SERVER_PORT!
echo.
echo 4. 检查网络连接:
echo    所有设备应该在同一 WiFi 或局域网上
echo.
echo 5. 查看应用日志:
echo    flutter logs -f
echo.
echo =======================================

pause
