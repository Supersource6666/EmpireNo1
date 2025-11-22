@echo off
REM Android 应用构建和部署脚本
REM 功能: 简化 Flutter Android 构建流程

setlocal enabledelayedexpansion

echo.
echo ============================================
echo   EmpireNo1 Android 应用构建脚本
echo ============================================
echo.

REM 检查 Flutter
flutter --version >nul 2>nul
if errorlevel 1 (
    echo [错误] Flutter 未找到，请先安装 Flutter SDK
    pause
    exit /b 1
)

REM 检查 Android SDK
where adb >nul 2>nul
if errorlevel 1 (
    echo [警告] adb 未在 PATH 中，请检查 Android SDK 安装
)

echo [信息] 可用命令：
echo   1. 清理构建
echo   2. 构建 Debug APK (快速构建，用于测试)
echo   3. 构建 Release APK (优化版，用于发布)
echo   4. 安装到连接的设备
echo   5. 运行到连接的设备
echo   6. 查看已连接的设备
echo   7. 查看实时日志
echo   8. 一键构建和安装
echo.

set /p choice="请选择操作 (1-8): "

if "%choice%"=="1" (
    goto :clean
) else if "%choice%"=="2" (
    goto :build_debug
) else if "%choice%"=="3" (
    goto :build_release
) else if "%choice%"=="4" (
    goto :install
) else if "%choice%"=="5" (
    goto :run
) else if "%choice%"=="6" (
    goto :devices
) else if "%choice%"=="7" (
    goto :logcat
) else if "%choice%"=="8" (
    goto :build_and_install
) else (
    echo [错误] 无效的选择
    exit /b 1
)

:clean
echo [步骤] 清理构建缓存...
flutter clean
echo [✓] 清理完成
goto :end

:build_debug
echo [步骤] 构建 Debug APK...
echo [信息] 这会花费 2-5 分钟...
flutter build apk --debug
if errorlevel 1 (
    echo [错误] 构建失败
    exit /b 1
)
echo [✓] Debug APK 构建完成
echo [位置] build/app/outputs/apk/debug/app-debug.apk
goto :end

:build_release
echo [步骤] 构建 Release APK...
echo [信息] 这会花费 5-10 分钟...
echo [信息] 优化的生产版本，体积更小，速度更快
flutter build apk --release
if errorlevel 1 (
    echo [错误] 构建失败
    exit /b 1
)
echo [✓] Release APK 构建完成
echo [位置] build/app/outputs/apk/release/app-release.apk
echo [大小] 
for %%A in (build/app/outputs/apk/release/app-release.apk) do echo %%~zA 字节
goto :end

:install
echo [步骤] 检查已连接的设备...
adb devices
set /p device_id="请输入设备 ID (或直接按 Enter 选择第一个): "
if "!device_id!"=="" (
    echo [信息] 使用第一个设备
    set device_id=""
)
echo [步骤] 安装应用...
if "!device_id!"=="" (
    adb install -r build/app/outputs/apk/debug/app-debug.apk
) else (
    adb -s !device_id! install -r build/app/outputs/apk/debug/app-debug.apk
)
if errorlevel 1 (
    echo [错误] 安装失败
    exit /b 1
)
echo [✓] 安装完成
goto :end

:run
echo [步骤] 列出可用设备...
adb devices
echo.
set /p device_id="请输入设备 ID (或直接按 Enter 使用 flutter run): "
if "!device_id!"=="" (
    echo [步骤] 使用 flutter run...
    flutter run
) else (
    echo [步骤] 在指定设备上运行...
    flutter run -d !device_id!
)
goto :end

:devices
echo [步骤] 已连接的设备列表：
adb devices -l
echo.
echo [信息] 要通过 WiFi 连接设备：
echo   1. 确保设备和电脑在同一网络
echo   2. 设备启用 USB 调试
echo   3. 运行: adb tcpip 5555
echo   4. 获取设备 IP (设置 - 关于手机 - IP 地址)
echo   5. 运行: adb connect DEVICE_IP:5555
goto :end

:logcat
echo [步骤] 显示实时日志...
echo [提示] 按 Ctrl+C 停止日志
adb logcat -s flutter
goto :end

:build_and_install
echo [步骤 1/3] 清理构建缓存...
flutter clean
echo [✓] 清理完成
echo.

echo [步骤 2/3] 构建 Debug APK...
flutter build apk --debug
if errorlevel 1 (
    echo [错误] 构建失败
    exit /b 1
)
echo [✓] 构建完成
echo.

echo [步骤 3/3] 安装到设备...
adb devices
echo.
set /p device_id="请输入设备 ID (或直接按 Enter 选择第一个): "
if "!device_id!"=="" (
    adb install -r build/app/outputs/apk/debug/app-debug.apk
) else (
    adb -s !device_id! install -r build/app/outputs/apk/debug/app-debug.apk
)
if errorlevel 1 (
    echo [错误] 安装失败
    exit /b 1
)
echo [✓] 安装完成

echo.
echo [步骤 4/3] 启动应用...
adb shell am start -n com.example.di_guo_1_hao/.MainActivity
echo [✓] 应用已启动
goto :end

:end
echo.
echo ============================================
echo   操作完成
echo ============================================
echo.
pause
