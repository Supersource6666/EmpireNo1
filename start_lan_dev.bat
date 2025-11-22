@echo off
REM LAN 局域网开发环境启动脚本
REM 功能: 启动后端 + Flutter 应用

setlocal enabledelayedexpansion

echo.
echo ============================================
echo   EmpireNo1 P2P 聊天系统 - LAN 启动脚本
echo ============================================
echo.

REM 获取本机 IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "ipv4 address"') do (
    set "ip=%%a"
    set "ip=!ip:~1!"
    goto :got_ip
)
:got_ip

echo [信息] 本机 IP 地址:
echo   %ip%
echo.

REM 检查 npm 安装
where npm >nul 2>nul
if errorlevel 1 (
    echo [错误] npm 未安装或未在 PATH 中
    echo [提示] 请先安装 Node.js
    pause
    exit /b 1
)

echo [步骤1] 启动后端服务...
start "后端服务 (3000)" cmd /k ^
    "cd /d D:\FlutterProject\delicious_food_selector\empire_no1_backend && ^
     npm install ^& ^
     set PORT=3000 ^& ^
     set HOST=0.0.0.0 ^& ^
     echo [✓] 后端启动成功: http://0.0.0.0:3000 ^& ^
     node server.js"

timeout /t 5 /nobreak
echo.

echo [步骤2] 启动 Flutter 应用...
REM 注意: 需要修改为实际的局域网 IP 或使用 0.0.0.0
start "Flutter 应用 (Web)" cmd /k ^
    "cd /d D:\FlutterProject\delicious_food_selector && ^
     flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080"

echo.
echo ============================================
echo   启动完成！
echo ============================================
echo.
echo [访问信息]
echo   后端 API: http://%ip%:3000/api/login
echo   Web 应用: http://%ip%:8080
echo   WebSocket: ws://%ip%:3000
echo.
echo [注意]
echo   - 确保防火墙允许 3000 和 8080 端口
echo   - 其他 LAN 设备可以访问: http://%ip%:8080
echo   - 登录时使用已注册的用户名和密码
echo.
pause
