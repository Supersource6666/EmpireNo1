@echo off
REM WiFi 设备管理工具 - 完整管理脚本
REM 功能：WiFi 连接、安装、运行、日志查看

setlocal enabledelayedexpansion

:menu
cls
echo.
echo ============================================
echo   WiFi 设备管理工具
echo ============================================
echo.
echo [1] 启用 WiFi 调试 (USB 转 TCP)
echo [2] 通过 WiFi 连接设备
echo [3] 查看已连接的设备
echo [4] 通过 WiFi 安装 APK
echo [5] 通过 WiFi 运行应用
echo [6] 通过 WiFi 查看日志
echo [7] 断开 WiFi 连接
echo [8] 切换回 USB 调试
echo [9] 完整的 WiFi 工作流 (一键操作)
echo [0] 退出
echo.
set /p choice="请选择 (0-9): "

if "%choice%"=="1" goto :enable_tcp
if "%choice%"=="2" goto :connect_wifi
if "%choice%"=="3" goto :list_devices
if "%choice%"=="4" goto :install_apk
if "%choice%"=="5" goto :run_app
if "%choice%"=="6" goto :view_logs
if "%choice%"=="7" goto :disconnect
if "%choice%"=="8" goto :switch_usb
if "%choice%"=="9" goto :workflow
if "%choice%"=="0" goto :end
echo [错误] 无效的选择
timeout /t 2
goto :menu

:enable_tcp
cls
echo.
echo ========== 启用 WiFi 调试 ==========
echo.
echo [信息] 确保设备通过 USB 连接
echo [信息] 设备上已启用 USB 调试
echo.
echo [步骤 1] 检查已连接的设备...
adb devices
echo.
set /p device="请输入设备序列号 (或按 Enter 使用第一个): "
echo.
echo [步骤 2] 启用 TCP 模式...
if "!device!"=="" (
    adb tcpip 5555
) else (
    adb -s !device! tcpip 5555
)
echo.
echo [✓] TCP 模式已启用
timeout /t 2 /nobreak
goto :menu

:connect_wifi
cls
echo.
echo ========== 通过 WiFi 连接设备 ==========
echo.
set /p device_ip="请输入设备 IP 地址: "
echo.
echo [步骤] 连接到 !device_ip!:5555...
adb connect !device_ip!:5555
echo.
echo [✓] 连接已建立
echo.
echo [验证] 检查连接...
adb devices
timeout /t 2 /nobreak
goto :menu

:list_devices
cls
echo.
echo ========== 已连接的设备 ==========
echo.
adb devices -l
echo.
pause
goto :menu

:install_apk
cls
echo.
echo ========== 通过 WiFi 安装 APK ==========
echo.
echo [检查] 可用的 APK 文件...
if exist "build\app\outputs\apk\debug\app-debug.apk" (
    echo [1] build/app/outputs/apk/debug/app-debug.apk
    set "apk1=build\app\outputs\apk\debug\app-debug.apk"
) else (
    echo [1] Debug APK 不存在
)

if exist "build\app\outputs\apk\release\app-release.apk" (
    echo [2] build/app/outputs/apk/release/app-release.apk
    set "apk2=build\app\outputs\apk\release\app-release.apk"
) else (
    echo [2] Release APK 不存在
)

echo.
set /p apk_choice="请选择要安装的 APK (1 or 2): "
echo.

if "!apk_choice!"=="1" (
    if defined apk1 (
        set "selected_apk=!apk1!"
    ) else (
        echo [错误] 选择的 APK 不存在
        timeout /t 2
        goto :menu
    )
) else if "!apk_choice!"=="2" (
    if defined apk2 (
        set "selected_apk=!apk2!"
    ) else (
        echo [错误] 选择的 APK 不存在
        timeout /t 2
        goto :menu
    )
) else (
    echo [错误] 无效的选择
    timeout /t 2
    goto :menu
)

echo [已连接的设备]
adb devices
echo.
set /p target_device="请输入目标设备 ID (或按 Enter 使用第一个): "
echo.
echo [步骤] 安装 APK...
if "!target_device!"=="" (
    adb install -r "!selected_apk!"
) else (
    adb -s !target_device! install -r "!selected_apk!"
)
echo.
echo [✓] 安装完成
timeout /t 2 /nobreak
goto :menu

:run_app
cls
echo.
echo ========== 通过 WiFi 运行应用 ==========
echo.
echo [已连接的设备]
adb devices
echo.
set /p target_device="请输入目标设备 ID (或按 Enter 使用第一个): "
echo.
echo [步骤] 启动应用...
if "!target_device!"=="" (
    adb shell am start -n com.example.di_guo_1_hao/.MainActivity
) else (
    adb -s !target_device! shell am start -n com.example.di_guo_1_hao/.MainActivity
)
echo.
echo [✓] 应用已启动
timeout /t 2 /nobreak
goto :menu

:view_logs
cls
echo.
echo ========== 通过 WiFi 查看日志 ==========
echo.
echo [已连接的设备]
adb devices
echo.
set /p target_device="请输入目标设备 ID (或按 Enter 使用第一个): "
echo.
echo [步骤] 查看实时日志 (按 Ctrl+C 停止)...
echo.
if "!target_device!"=="" (
    adb logcat -s flutter
) else (
    adb -s !target_device! logcat -s flutter
)
goto :menu

:disconnect
cls
echo.
echo ========== 断开 WiFi 连接 ==========
echo.
echo [已连接的设备]
adb devices
echo.
set /p device_addr="请输入设备地址 (例: 192.168.1.105:5555): "
echo.
adb disconnect !device_addr!
echo.
echo [✓] 已断开连接
timeout /t 2 /nobreak
goto :menu

:switch_usb
cls
echo.
echo ========== 切换回 USB 调试 ==========
echo.
set /p device="请输入设备序列号: "
echo.
adb -s !device! usb
echo.
echo [✓] 已切换回 USB 模式
timeout /t 2 /nobreak
goto :menu

:workflow
cls
echo.
echo ========== WiFi 工作流 (一键操作) ==========
echo.
echo [步骤 1/4] 检查已连接的设备...
adb devices
echo.
set /p device="请输入设备序列号 (用于启用 TCP，按 Enter 跳过): "
echo.

if not "!device!"=="" (
    echo [步骤 1] 启用 TCP 模式...
    adb -s !device! tcpip 5555
    timeout /t 3 /nobreak
    echo.
)

echo [步骤 2] 获取设备 IP 地址...
set /p device_ip="请输入设备 IP 地址: "
echo.

echo [步骤 3] 连接到设备...
adb connect !device_ip!:5555
timeout /t 2 /nobreak
echo.

echo [步骤 4] 选择要安装的 APK...
if exist "build\app\outputs\apk\debug\app-debug.apk" (
    echo [1] Debug APK
)
if exist "build\app\outputs\apk\release\app-release.apk" (
    echo [2] Release APK
)
echo.
set /p apk_choice="请选择 (1 or 2): "

if "!apk_choice!"=="1" (
    set "apk_file=build\app\outputs\apk\debug\app-debug.apk"
) else if "!apk_choice!"=="2" (
    set "apk_file=build\app\outputs\apk\release\app-release.apk"
) else (
    echo [错误] 无效的选择
    timeout /t 2
    goto :menu
)

echo.
echo [步骤 5] 安装 APK...
adb install -r "!apk_file!"
echo.
echo [✓] 工作流完成！
echo.
timeout /t 3 /nobreak
goto :menu

:end
echo.
echo 感谢使用！
echo.
exit /b 0
