@echo off
REM P2P 聊天系统 Nginx Windows 快速部署脚本
REM
REM 使用方法: 
REM   以管理员身份运行此脚本
REM   右键 -> 以管理员身份运行

setlocal enabledelayedexpansion
color 0A

echo ======================================
echo P2P 聊天系统 Nginx 部署工具 (Windows)
echo ======================================
echo.

REM 检查管理员权限
net session >nul 2>&1
if errorlevel 1 (
    echo [错误] 需要管理员权限，请以管理员身份运行此脚本
    pause
    exit /b 1
)

echo [步骤 1/4] 检查 Nginx 安装...

REM 检查 Nginx 是否已安装
if not exist "C:\nginx\nginx.exe" (
    echo [信息] Nginx 未安装，下面将安装 Nginx
    echo.
    
    REM 检查 Chocolatey
    where choco >nul 2>&1
    if errorlevel 1 (
        echo [错误] 未找到 Chocolatey，请先安装 Chocolatey
        echo        访问: https://chocolatey.org/install
        pause
        exit /b 1
    )
    
    echo [安装中] 使用 Chocolatey 安装 Nginx...
    choco install nginx -y
    
    if errorlevel 1 (
        echo [错误] Nginx 安装失败
        pause
        exit /b 1
    )
    echo [成功] Nginx 安装完成
) else (
    echo [成功] 检测到 Nginx: C:\nginx\nginx.exe
)

echo.
echo [步骤 2/4] 配置 Nginx...

REM 备份原配置
if exist "C:\nginx\conf\nginx.conf" (
    copy "C:\nginx\conf\nginx.conf" "C:\nginx\conf\nginx.conf.bak"
    echo [备份] 原配置已备份为 nginx.conf.bak
)

REM 创建新配置
(
echo user nobody;
echo worker_processes auto;
echo events { worker_connections 1024; }
echo http {
echo     include mime.types;
echo     default_type application/octet-stream;
echo.
echo     sendfile on;
echo     keepalive_timeout 65;
echo     client_max_body_size 20M;
echo.
echo     upstream backend {
echo         server 127.0.0.1:3000;
echo         keepalive 32;
echo     }
echo.
echo     server {
echo         listen 80;
echo         server_name _;
echo.
echo         location /api/ {
echo             proxy_pass http://backend;
echo             proxy_http_version 1.1;
echo             proxy_set_header Connection "";
echo             proxy_set_header Host $host;
echo             proxy_set_header X-Real-IP $remote_addr;
echo             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
echo             proxy_connect_timeout 60s;
echo             proxy_send_timeout 60s;
echo             proxy_read_timeout 60s;
echo         }
echo.
echo         location /ws {
echo             proxy_pass http://backend;
echo             proxy_http_version 1.1;
echo             proxy_set_header Upgrade $http_upgrade;
echo             proxy_set_header Connection "upgrade";
echo             proxy_set_header Host $host;
echo             proxy_set_header X-Real-IP $remote_addr;
echo             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
echo             proxy_read_timeout 86400;
echo             proxy_send_timeout 86400;
echo             proxy_buffering off;
echo         }
echo.
echo         location / {
echo             proxy_pass http://backend;
echo             proxy_http_version 1.1;
echo             proxy_set_header Connection "";
echo             proxy_set_header Host $host;
echo             proxy_set_header X-Real-IP $remote_addr;
echo             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
echo         }
echo.
echo         location /health {
echo             access_log off;
echo             return 200 "OK";
echo         }
echo     }
echo }
) > "C:\nginx\conf\nginx.conf"

echo [成功] Nginx 配置已创建
echo.

echo [步骤 3/4] 验证配置...
cd /d C:\nginx
nginx.exe -t
if errorlevel 1 (
    echo [错误] 配置验证失败
    pause
    exit /b 1
)
echo [成功] 配置验证通过
echo.

echo [步骤 4/4] 启动 Nginx...

REM 停止现有的 Nginx
taskkill /F /IM nginx.exe >nul 2>&1

REM 等待进程关闭
timeout /t 1 >nul

REM 启动 Nginx
cd /d C:\nginx
start nginx.exe

REM 等待启动
timeout /t 2 >nul

REM 验证
netstat -ano | findstr :80 >nul
if errorlevel 1 (
    echo [错误] Nginx 启动失败
    pause
    exit /b 1
)

echo [成功] Nginx 启动成功
echo.

echo ======================================
echo [完成] 部署完毕！
echo ======================================
echo.

REM 获取本机 IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr "192"') do (
    set "LOCAL_IP=%%a"
    goto found_ip
)
set "LOCAL_IP=127.0.0.1"

:found_ip
set "LOCAL_IP=!LOCAL_IP: =!"

echo [配置信息]
echo   访问地址: http://!LOCAL_IP!
echo   API 地址: http://!LOCAL_IP!/api
echo   WebSocket: ws://!LOCAL_IP!/ws
echo   本地地址: http://localhost
echo.

echo [后续步骤]
echo   1. 启动后端服务:
echo      cd backend
echo      npm install
echo      node server.js
echo.
echo   2. 修改 Flutter 配置 (lib/config.dart):
echo      static const String wsHost = '!LOCAL_IP!';
echo      static const int wsPort = 80;
echo      static String get wsUrl =^> 'ws://\$wsHost:\$wsPort/ws';
echo.
echo   3. 运行 Flutter 应用:
echo      flutter run
echo.

echo [常用命令]
echo   启动: cd C:\nginx ^&^& nginx.exe
echo   停止: nginx.exe -s stop
echo   重启: nginx.exe -s reload
echo   日志: C:\nginx\logs\error.log
echo.

echo [防火墙配置]
echo   如果无法访问，请允许 Nginx 通过防火墙:
echo   powershell -Command "New-NetFirewallRule -DisplayName 'Allow Nginx' -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow"
echo.

echo [验证部署]
echo   打开浏览器访问: http://!LOCAL_IP!/health
echo   应该看到: OK
echo.

pause
