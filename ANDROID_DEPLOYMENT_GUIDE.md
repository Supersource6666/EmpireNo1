# Android 设备 P2P 聊天系统 - 完整部署指南

## 📱 目录

- [系统要求](#系统要求)
- [Android 权限配置](#android-权限配置)
- [构建和打包](#构建和打包)
- [部署到设备](#部署到设备)
- [故障排查](#故障排查)
- [性能优化](#性能优化)

---

## 🔧 系统要求

### 开发环境

```
Flutter >= 3.9.2
Dart >= 3.9.2
Android SDK >= 21 (API 21 - Android 5.0)
Android Studio (可选但推荐)
Node.js >= 14.0 (后端服务)
```

### 设备要求

```
Android 5.0+ (API 21+)
最小内存: 1GB RAM (推荐 2GB+)
存储空间: 200MB+ 可用
网络: WiFi 或移动网络
```

---

## 🔐 Android 权限配置

### 已添加的权限

编辑 `android/app/src/main/AndroidManifest.xml` 已包含以下权限：

```xml
<!-- 网络相关 -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>

<!-- 存储相关 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<!-- 音频视频 -->
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>

<!-- 后台运行 -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### 运行时权限请求

Android 6.0+ 需要在运行时请求权限。已通过 `permission_handler` 包支持。

---

## 🏗️ 构建和打包

### 步骤1：获取依赖

```powershell
cd D:\FlutterProject\delicious_food_selector
flutter pub get
```

### 步骤2：清理构建缓存

```powershell
flutter clean
```

### 步骤3：构建 Debug APK（用于测试）

```powershell
# 快速构建，用于本地测试
flutter build apk --debug

# 输出: build/app/outputs/apk/debug/app-debug.apk
```

### 步骤4：构建 Release APK（生产版本）

```powershell
# 优化的生产版本
flutter build apk --release

# 输出: build/app/outputs/apk/release/app-release.apk
```

### 步骤5：构建 Bundle（用于 Google Play）

```powershell
flutter build appbundle --release

# 输出: build/app/outputs/bundle/release/app-release.aab
```

---

## 📲 部署到设备

### 方式1：使用 ADB 安装（推荐开发）

#### 连接设备

```powershell
# 列出已连接的设备
adb devices

# 输出示例：
# List of attached devices
# emulator-5554          device
# FA7AX1A123456         device
```

#### 使用 Flutter 直接运行

```powershell
# 自动选择设备（如只有一个设备）
flutter run

# 指定特定设备
flutter run -d <device-id>

# 例如：
flutter run -d FA7AX1A123456
```

#### 手动使用 ADB 安装

```powershell
# 安装 APK
adb install build/app/outputs/apk/debug/app-debug.apk

# 安装并运行
adb install -r build/app/outputs/apk/debug/app-debug.apk
adb shell am start -n com.example.di_guo_1_hao/.MainActivity

# 查看实时日志
adb logcat -s flutter
```

### 方式2：通过 USB 数据线连接

1. 连接 Android 设备到电脑
2. 在设备上启用 USB 调试
   - 设置 → 关于手机 → 连续按5次"版本号"
   - 返回 → 开发者选项 → USB 调试
3. 运行：
   ```powershell
   flutter run
   ```

### 方式3：通过无线网络连接（LAN）

1. 确保设备和电脑在同一网络
2. 使用 ADB over TCP：

```powershell
# 在设备上启用 USB 调试后

# 步骤1：连接 USB，启用 TCP 模式
adb tcpip 5555

# 步骤2：获取设备 IP 地址
adb shell ip addr show wlan0
# 或查看设备设置 → 关于手机 → IP 地址

# 步骤3：通过 WiFi 连接
adb connect <device-ip>:5555

# 步骤4：取消 USB 连接（可选）

# 步骤5：检查连接
adb devices

# 步骤6：运行应用
flutter run
```

---

## 🌐 局域网访问配置

### 后端服务配置

确保后端以监听所有网卡的方式启动：

```powershell
# Windows
$env:HOST='0.0.0.0'
$env:PORT='3000'
node server.js

# 或使用启动脚本
D:\FlutterProject\delicious_food_selector\start_lan_dev.bat
```

### Flutter 应用配置

编辑 `lib/config.dart` 确保使用正确的 IP 地址：

```dart
static const String wsHost = '192.168.1.102';  // 改为你的服务器 IP
static const String DEPLOYMENT_MODE = 'direct';  // 直连模式
```

### Android 设备访问后端

```
API 地址: http://192.168.1.102:3000/api/login
WebSocket: ws://192.168.1.102:3000
```

---

## 🐛 故障排查

### 问题1：应用无法连接到后端

**症状**：登录时显示 "failed to fetch"

**解决步骤**：

1. 确认后端运行：
   ```powershell
   curl http://192.168.1.102:3000/api/login
   ```

2. 检查设备网络：
   ```powershell
   # 在 Android 设备上
   adb shell ping 192.168.1.102
   ```

3. 检查防火墙：
   ```powershell
   # Windows 防火墙允许 3000 端口
   netsh advfirewall firewall add rule name="Node.js Port 3000" `
     dir=in action=allow protocol=tcp localport=3000
   ```

4. 更新 config.dart 中的 IP 地址

### 问题2：WebSocket 连接不稳定

**症状**：断断续续的连接，消息未送出

**解决步骤**：

1. 检查网络连接稳定性：
   ```powershell
   # 在 Android 设备上
   adb shell ping -c 10 8.8.8.8
   ```

2. 查看应用日志：
   ```powershell
   adb logcat -s flutter
   ```

3. 增加重连超时：
   ```dart
   // 在 websocket_manager.dart 中
   static const Duration _baseReconnectDelay = Duration(seconds: 3);
   ```

### 问题3：应用运行缓慢

**症状**：应用响应慢，UI 卡顿

**解决步骤**：

1. 使用 Release 构建：
   ```powershell
   flutter run --release
   ```

2. 检查内存使用：
   ```powershell
   adb shell dumpsys meminfo com.example.di_guo_1_hao
   ```

3. 启用性能监控：
   ```dart
   // main.dart
   debugPrintBeginFrameBanner = true;
   debugPrintEndFrameBanner = true;
   ```

### 问题4：权限被拒绝

**症状**：应用启动后立即崩溃或某些功能不可用

**解决步骤**：

1. 检查权限状态：
   ```powershell
   adb shell pm list permissions
   ```

2. 清除应用数据后重新安装：
   ```powershell
   adb shell pm clear com.example.di_guo_1_hao
   flutter run
   ```

3. 检查 AndroidManifest.xml 权限声明

### 问题5：应用无法安装

**症状**：adb install 返回错误

**常见原因和解决**：

```powershell
# 错误: INSTALL_FAILED_VERSION_DOWNGRADE
# 解决: 先卸载旧版本
adb uninstall com.example.di_guo_1_hao

# 错误: INSTALL_FAILED_INSUFFICIENT_STORAGE
# 解决: 清理设备存储空间

# 错误: INSTALL_FAILED_INVALID_APK
# 解决: 重新构建 APK
flutter clean
flutter build apk --debug
```

---

## ⚡ 性能优化

### 1. Release 模式构建

```powershell
# 使用 Release 构建获得最佳性能
flutter build apk --release

# 大小优化
flutter build apk --release --split-per-abi
```

### 2. 代码优化

```dart
// 避免重复构建 widget
const MyWidget()  // 使用 const 标记

// 使用 RepaintBoundary 限制重绘范围
RepaintBoundary(
  child: widget,
)
```

### 3. 网络优化

```dart
// 设置合理的超时时间
http.get(url).timeout(const Duration(seconds: 10))

// 批量请求
// 避免多个并发请求，使用队列
```

### 4. 内存优化

```dart
// 及时释放资源
@override
void dispose() {
  _controller.dispose();
  _wsManager.dispose();
  super.dispose();
}

// 避免内存泄漏
StreamSubscription? _subscription;

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

---

## 📋 完整部署流程

### 第1天：开发和测试

```powershell
# 1. 启动后端
D:\FlutterProject\delicious_food_selector\start_lan_dev.bat

# 2. 运行 Flutter（Web 版测试）
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080

# 3. 运行 Flutter（Android 设备测试）
flutter run
```

### 第2天：构建 APK

```powershell
# 1. 清理构建
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 构建 Release APK
flutter build apk --release

# 4. APK 位置
# build/app/outputs/apk/release/app-release.apk
```

### 第3天：分发

```powershell
# 1. 签名 APK (如果需要发布)
# (需要配置 keystore)

# 2. 直接分发 APK
# app-release.apk 可以直接分享给用户

# 3. 用户安装
adb install app-release.apk
```

---

## 🎯 测试清单

- [ ] 设备可以通过 USB 连接到开发机
- [ ] Flutter 可以运行在 Android 设备上
- [ ] 应用可以登录
- [ ] WebSocket 连接成功
- [ ] 可以发送和接收聊天消息
- [ ] 在网络切换时可以自动重连
- [ ] 在后台运行时网络连接不中断
- [ ] Release 版本运行流畅
- [ ] 权限请求正常
- [ ] 电池使用量在正常范围内

---

## 📚 参考资源

- [Flutter Android 官方文档](https://flutter.dev/docs/deployment/android)
- [Android 开发者文档](https://developer.android.com/docs)
- [ADB 命令参考](https://developer.android.com/tools/adb)
- [WebSocket 最佳实践](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

---

## 🆘 获取帮助

如遇到问题，请：

1. 查看应用日志：`adb logcat`
2. 检查后端日志：看服务器窗口输出
3. 查看此文档的故障排查部分
4. 检查 GitHub Issues（如有项目仓库）

---

**最后更新**: 2025-11-22  
**版本**: 1.0  
**状态**: ✅ 生产就绪
