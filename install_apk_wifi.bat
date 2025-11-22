@echo off
REM WiFi Wireless APK Installation Script
REM Function: Install APK to Android device via WiFi

setlocal enabledelayedexpansion

echo.
echo ============================================
echo   WiFi Wireless APK Installation Script
echo ============================================
echo.

REM Check adb
where adb >nul 2>nul
if errorlevel 1 (
    echo [ERROR] adb not found, please check Android SDK installation
    pause
    exit /b 1
)

echo [Step 1/5] Display connected devices...
adb devices
echo.

set /p use_device="Enter device serial number (press Enter to use first device): "

REM ========== Enable USB Connection Mode ==========
echo.
echo [Step 2/5] Enable ADB over TCP mode...
if "!use_device!"=="" (
    adb tcpip 5555
) else (
    adb -s !use_device! tcpip 5555
)

if errorlevel 1 (
    echo [ERROR] Failed to enable TCP mode
    echo [TIP] Make sure device is connected via USB and USB debugging is enabled
    pause
    exit /b 1
)

timeout /t 3 /nobreak
echo [✓] TCP mode enabled
echo.

REM ========== Get Device IP ==========
echo [Step 3/5] Get device IP address...
echo [TIP] Get IP from device: Settings - About Phone - IP Address
echo [Or use the following command to auto-detect]
echo.

REM Try to auto-detect device IP
if "!use_device!"=="" (
    adb shell ip addr show wlan0 2>nul | findstr "inet " > temp_ip.txt
) else (
    adb -s !use_device! shell ip addr show wlan0 2>nul | findstr "inet " > temp_ip.txt
)

REM Parse IP
set "device_ip="
for /f "tokens=2" %%a in (temp_ip.txt) do (
    set device_ip=%%a
    REM Remove /24 subnet mark
    set "device_ip=!device_ip:/24=!"
    goto :ip_found
)

:ip_found
del temp_ip.txt 2>nul

if "!device_ip!"=="" (
    set /p device_ip="Please enter device IP address manually (example: 192.168.1.105): "
) else (
    echo [Auto-detected] Device IP: !device_ip!
    set /p confirm="Confirm this IP address? (Y/n): "
    if /i "!confirm!"=="n" (
        set /p device_ip="Please enter correct IP address: "
    )
)

echo.

REM ========== Connect Device ==========
echo [Step 4/5] Connect device via WiFi...
adb connect !device_ip!:5555

if errorlevel 1 (
    echo [ERROR] Connection failed
    echo [TIP] Please check:
    echo   1. Device and computer are on the same network
    echo   2. IP address is correct
    echo   3. USB cable is disconnected (optional)
    pause
    exit /b 1
)

timeout /t 2 /nobreak
echo [✓] WiFi connection successful
echo.

REM ========== Check APK File ==========
echo [Step 5/5] Install APK...
echo.

if not exist "build\app\outputs\apk\debug\app-debug.apk" (
    if not exist "build\app\outputs\apk\release\app-release.apk" (
        echo [ERROR] APK file not found
        echo [TIP] Please build APK first:
        echo   flutter build apk --debug
        echo   or
        echo   flutter build apk --release
        pause
        exit /b 1
    ) else (
        set "apk_file=build\app\outputs\apk\release\app-release.apk"
        echo [INFO] Using Release APK
    )
) else (
    set "apk_file=build\app\outputs\apk\debug\app-debug.apk"
    echo [INFO] Using Debug APK
)

echo [Step 5/5] Install APK to device...
adb -s !device_ip!:5555 install -r "!apk_file!"

if errorlevel 1 (
    echo.
    echo [ERROR] Installation failed
    echo [Common reasons]:
    echo   1. Network connection interrupted
    echo   2. Device rejected connection
    echo   3. APK file corrupted
    echo.
    echo [Solutions]:
    echo   1. Reconnect WiFi
    echo   2. Restart device
    echo   3. Rebuild APK
    pause
    exit /b 1
)

echo.
echo [✓] Installation successful!
echo.
echo ============================================
echo   Installation Complete
echo ============================================
echo.
echo [Next Steps]:
echo   1. Find app icon on device
echo   2. Tap to open app
echo   3. Or use command to launch:
echo      adb shell am start -n com.example.di_guo_1_hao/.MainActivity
echo.
pause
