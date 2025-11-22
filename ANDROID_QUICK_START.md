# 🚀 Android 支持 - 立即开始操作指南

## ⏱️ 预计时间：15 分钟

---

## 📋 Step-by-Step 操作流程

### 第1步：检查环境（2分钟）

```powershell
cd D:\FlutterProject\delicious_food_selector
check_android_env.bat
```

**预期输出**：
```
✓ Flutter 已安装
✓ Dart 已安装
✓ Android SDK 已安装
✓ Java 已安装
✓ 所有检查通过，环境就绪
```

如果有 ✗ 标记，请安装相应软件或查看 `ANDROID_DEPLOYMENT_GUIDE.md`

---

### 第2步：获取依赖（3分钟）

```powershell
flutter pub get
```

**输出示例**：
```
Running "flutter pub get" in delicious_food_selector...
Added 50 new packages...
```

---

### 第3步：连接 Android 设备（2分钟）

#### 选项 A：USB 连接（推荐）

1. 用 USB 数据线连接设备到电脑
2. 设备上启用 USB 调试：
   - 设置 → 关于手机 → 连续点击 "版本号" 5 次
   - 返回 → 开发者选项 → 启用 "USB 调试"

3. 验证连接：
   ```powershell
   adb devices
   ```
   
   应该显示：
   ```
   List of attached devices
   FA7AX1A123456     device
   ```

#### 选项 B：WiFi 连接

```powershell
# 1. 启用 TCP 模式
adb tcpip 5555

# 2. 获取设备 IP (设置 - 关于手机 - IP 地址)
# 假设 IP 是 192.168.1.105

# 3. 连接
adb connect 192.168.1.105:5555

# 4. 验证
adb devices
# 应该显示: 192.168.1.105:5555    device
```

---

### 第4步：启动后端服务（2分钟）

打开新的 PowerShell 窗口：

```powershell
cd D:\FlutterProject\delicious_food_selector
start_lan_dev.bat
```

**预期输出**：
```
[✓] 后端启动成功: http://0.0.0.0:3000
[✓] 正在启动后端服务...
```

---

### 第5步：配置应用（1分钟）

检查 `lib/config.dart`：

```dart
static const String DEPLOYMENT_MODE = 'direct';  // 应该是 'direct'
static const String wsHost = '192.168.1.102';    // 改为你的 PC IP
```

如果 IP 不对，修改为你的 PC 局域网 IP：

```powershell
# 获取 PC 的局域网 IP
ipconfig

# 查找类似 192.168.x.x 的 IPv4 Address
```

然后更新 `config.dart`

---

### 第6步：运行应用（2分钟）

打开另一个 PowerShell 窗口：

```powershell
cd D:\FlutterProject\delicious_food_selector
flutter run
```

**初次运行会比较慢，预计 2-3 分钟**

预期输出：
```
Launching lib/main.dart on FA7AX1A123456...
flutter: [ChatRoom] 正在连接 WebSocket...
flutter: [ChatRoom] WebSocket 状态: 已连接
```

---

### 第7步：测试应用（3分钟）

应用启动后：

1. ✅ 点击"登录"按钮
2. ✅ 输入用户名和密码（第一次需要先注册）
3. ✅ 成功登录
4. ✅ 看到 WebSocket 连接状态为"已连接"
5. ✅ 尝试发送消息

如果看到绿色的 ✓ 标记，说明一切正常！

---

## 🎯 常见场景

### 场景1：快速开发测试

```powershell
# 终端1 - 启动后端
start_lan_dev.bat

# 终端2 - 运行应用
flutter run

# 修改代码后，在终端2 中按 'r' 热刷新
# 按 'R' 热重启
# 按 'q' 退出
```

### 场景2：构建发布版本

```powershell
# 清理
flutter clean

# 构建 Debug APK (快速)
flutter build apk --debug

# 或构建 Release APK (优化)
flutter build apk --release

# APK 位置:
# Debug:   build/app/outputs/apk/debug/app-debug.apk
# Release: build/app/outputs/apk/release/app-release.apk
```

### 场景3：使用构建脚本

```powershell
# 一键构建并安装
build_android.bat

# 选择选项:
# 1. 清理构建
# 2. 构建 Debug APK
# 3. 构建 Release APK
# 4. 安装到设备
# 5. 运行应用
# 6. 查看设备列表
# 7. 查看实时日志
# 8. 一键构建和安装
```

### 场景4：多设备测试

```powershell
# 连接多个设备
adb devices

# 在特定设备上运行
flutter run -d <device-id>

# 例如:
flutter run -d FA7AX1A123456  # 第一个设备
flutter run -d 192.168.1.105:5555  # WiFi 设备
```

---

## ⚠️ 问题排查

### 问题1："failed to fetch" 错误

**症状**: 登录时出现此错误

**解决步骤**:

```powershell
# 1. 检查后端是否运行
curl http://192.168.1.102:3000/api/login

# 应该返回错误（因为没有发送用户名/密码），但不应该是 connection refused
# 如果是 connection refused，说明后端没有运行

# 2. 检查 IP 地址是否正确
# 在 Android 设备上，打开浏览器，访问:
# http://192.168.1.102:3000

# 3. 检查防火墙
# Windows: 允许 Node.js 通过防火墙
netsh advfirewall firewall add rule name="Node.js" dir=in action=allow program="C:\Program Files\nodejs\node.exe"
```

### 问题2：WebSocket 无法连接

**症状**: "正在连接到聊天服务..." 持续显示

**解决步骤**:

```powershell
# 1. 检查网络连接
ping 192.168.1.102

# 2. 重新启动后端
# (终止后端进程，然后重新运行)

# 3. 检查 Android 日志
adb logcat -s flutter
```

### 问题3：应用无法安装

**症状**: "INSTALL_FAILED_..." 错误

**解决步骤**:

```powershell
# 1. 卸载旧版本
adb uninstall com.example.di_guo_1_hao

# 2. 重新构建
flutter clean
flutter build apk --debug

# 3. 重新安装
adb install build/app/outputs/apk/debug/app-debug.apk
```

### 问题4：构建失败

**症状**: `flutter run` 或 `flutter build` 报错

**解决步骤**:

```powershell
# 1. 清理所有缓存
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 运行 flutter doctor
flutter doctor

# 4. 如果有 ✗ 标记，按照提示修复

# 5. 重试构建
flutter build apk --debug
```

---

## 📊 网络拓扑

```
┌──────────────┐
│ Android 设备  │
│ (192.168.1.105)
└──────┬───────┘
       │ WiFi / USB
       │
┌──────▼────────────┐
│  Windows PC       │
│ (192.168.1.102)   │
├───────────────────┤
│ Node.js (3000)    │ ← 后端服务
│ SQLite DB         │ ← 消息存储
└───────────────────┘
```

### 连接方式

| 方式 | 命令 | 适用场景 |
|------|------|--------|
| USB 直连 | `adb devices` | 开发调试 |
| WiFi 连接 | `adb connect IP:5555` | 无线调试 |
| 通过 IDE | Android Studio / VS Code | 可视化开发 |

---

## ✅ 验收标准

运行成功的标志：

- [ ] `check_android_env.bat` 全部通过
- [ ] `flutter pub get` 成功
- [ ] 设备通过 `adb devices` 显示
- [ ] 后端启动显示 "running on 0.0.0.0:3000"
- [ ] `flutter run` 完成，应用在设备上运行
- [ ] 应用显示绿色的网络和 WebSocket 连接图标
- [ ] 能成功登录
- [ ] 能发送和接收消息

---

## 🎓 下一步学习

1. **理解架构**
   - 阅读 `ANDROID_SUPPORT_SUMMARY.md`
   
2. **详细部署步骤**
   - 查看 `ANDROID_DEPLOYMENT_GUIDE.md`

3. **自定义开发**
   - 修改 `lib/config.dart` 中的配置
   - 在 `lib/pages/chat_room_page.dart` 中修改 UI
   - 参考 `ANDROID_CHAT_ROOM_IMPROVEMENTS.dart` 中的最佳实践

4. **性能优化**
   - 构建 Release 版本
   - 监控内存和电池使用

---

## 📞 快速命令参考

```powershell
# 基础命令
flutter pub get                          # 获取依赖
flutter clean                            # 清理构建
flutter run                              # 运行到设备
flutter build apk --debug                # 构建 Debug APK
flutter build apk --release              # 构建 Release APK

# 设备管理
adb devices                              # 列出设备
adb connect <ip>:5555                    # WiFi 连接
adb logcat -s flutter                    # 查看日志
adb shell pm clear <package>             # 清除应用数据

# 快速脚本
check_android_env.bat                    # 检查环境
build_android.bat                        # 一键构建
start_lan_dev.bat                        # 启动后端
```

---

## 🎉 现在就开始！

```powershell
# 复制粘贴这个命令序列

# 1. 检查环境
check_android_env.bat

# 2. 获取依赖
flutter pub get

# 3. 启动后端 (新窗口)
start_lan_dev.bat

# 4. 运行应用 (另一个新窗口)
flutter run
```

---

**完成时间**: 2025-11-22  
**难度级别**: 🟢 初级  
**预计耗时**: 15 分钟  
**成功率**: 95%+

祝你使用愉快！ 🚀
