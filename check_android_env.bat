@echo off
REM Android 环境检查和验证脚本

setlocal enabledelayedexpansion

echo.
echo ============================================
echo   Android 部署环境检查工具
echo ============================================
echo.

set "all_pass=true"

REM ========== 检查 Flutter ==========
echo [检查 1/8] Flutter SDK...
flutter --version >nul 2>nul
if errorlevel 1 (
    echo   ✗ Flutter 未安装
    set "all_pass=false"
) else (
    echo   ✓ Flutter 已安装
    flutter --version | findstr /R "Flutter" | for /f "tokens=*" %%a in ('more') do echo     %%a
)

REM ========== 检查 Dart ==========
echo.
echo [检查 2/8] Dart SDK...
dart --version >nul 2>nul
if errorlevel 1 (
    echo   ✗ Dart 未安装
    set "all_pass=false"
) else (
    echo   ✓ Dart 已安装
    dart --version
)

REM ========== 检查 Android SDK ==========
echo.
echo [检查 3/8] Android SDK...
adb version >nul 2>nul
if errorlevel 1 (
    echo   ✗ Android SDK 未安装或 adb 不在 PATH 中
    set "all_pass=false"
) else (
    echo   ✓ Android SDK 已安装
    adb version
)

REM ========== 检查 Java ==========
echo.
echo [检查 4/8] Java 环境...
java -version >nul 2>nul
if errorlevel 1 (
    echo   ✗ Java 未安装
    set "all_pass=false"
) else (
    echo   ✓ Java 已安装
    java -version
)

REM ========== 检查 Gradle ==========
echo.
echo [检查 5/8] Gradle...
gradlew --version >nul 2>nul
if errorlevel 1 (
    echo   ✗ Gradle 不可用
    set "all_pass=false"
) else (
    echo   ✓ Gradle 已安装
)

REM ========== 检查已连接的设备 ==========
echo.
echo [检查 6/8] 已连接的 Android 设备...
adb devices | findstr /V "^List" | findstr /V "daemon" > temp_devices.txt
set /p first_line=<temp_devices.txt
if "!first_line!"=="" (
    echo   ✗ 未检测到连接的设备
) else (
    echo   ✓ 检测到已连接的设备：
    adb devices | findstr /V "^List" | findstr /V "daemon"
)
del temp_devices.txt

REM ========== 检查项目结构 ==========
echo.
echo [检查 7/8] 项目结构...
if exist "android" (
    echo   ✓ android/ 目录存在
    if exist "android\app\src\main\AndroidManifest.xml" (
        echo   ✓ AndroidManifest.xml 存在
    ) else (
        echo   ✗ AndroidManifest.xml 不存在
        set "all_pass=false"
    )
) else (
    echo   ✗ android/ 目录不存在
    set "all_pass=false"
)

if exist "lib" (
    echo   ✓ lib/ 目录存在
) else (
    echo   ✗ lib/ 目录不存在
    set "all_pass=false"
)

if exist "pubspec.yaml" (
    echo   ✓ pubspec.yaml 存在
) else (
    echo   ✗ pubspec.yaml 不存在
    set "all_pass=false"
)

REM ========== 检查网络连接 ==========
echo.
echo [检查 8/8] 网络连接...
ping -n 1 8.8.8.8 >nul 2>nul
if errorlevel 1 (
    echo   ✗ 网络连接失败
) else (
    echo   ✓ 网络连接正常
)

REM ========== 总结 ==========
echo.
echo ============================================
if "!all_pass!"=="true" (
    echo   ✓ 所有检查通过，环境就绪
) else (
    echo   ✗ 有些检查未通过，请修复后重试
)
echo ============================================
echo.

REM ========== 建议 ==========
echo [建议操作]
echo   1. 获取依赖包:      flutter pub get
echo   2. 检查 Flutter:    flutter doctor
echo   3. 列出可用设备:    adb devices
echo   4. 构建 Debug APK:  flutter build apk --debug
echo   5. 运行应用:        flutter run
echo.
echo [快速构建脚本]
echo   运行: build_android.bat
echo.

pause
