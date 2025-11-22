# WiFi 安装 APK 完整指南

## 📱 快速开始（3 步）

### 步骤 1️⃣：使用自动脚本

最简单的方式：

```powershell
install_apk_wifi.bat
```

脚本会自动引导你完成整个过程。

### 步骤 2️⃣：或使用管理工具

更多功能的选择：

```powershell
wifi_device_manager.bat
```

选择对应的菜单项（1-9）。

### 步骤 3️⃣：手动方式

如果上述脚本有问题，可以手动操作。

---

## 🔧 详细步骤（手动方式）

### 前置准备

#### 1. 确保设备已准备好

- ✅ 设备通过 USB 数据线连接到电脑
- ✅ 设备上启用 USB 调试
  - 设置 → 关于手机 → 连续点击 "版本号" 5 次
  - 返回 → 开发者选项 → 启用 "USB 调试"
- ✅ 设备和电脑在同一 WiFi 网络

#### 2. 获取设备 IP 地址

**方式 A：从设备获取**

设置 → 关于手机 → IP 地址

（或 设置 → WiFi → 连接的网络 → IP 地址）

**方式 B：使用命令行获取**

```powershell
adb shell ip addr show wlan0
```

输出示例：
```
inet 192.168.1.105/24 brd 192.168.1.255 scope global dynamic wlan0
```

IP 地址是：`192.168.1.105`

#### 3. 构建 APK（如果还没有）

```powershell
# Debug 版本（快速）
flutter build apk --debug

# Release 版本（优化）
flutter build apk --release
```

输出位置：
- Debug: `build/app/outputs/apk/debug/app-debug.apk`
- Release: `build/app/outputs/apk/release/app-release.apk`

---

## 📡 WiFi 连接过程

### 步骤 1：启用 TCP 模式

在电脑上运行（设备仍需 USB 连接）：

```powershell
adb tcpip 5555
```

输出：
```
restarting in TCP mode port: 5555
```

### 步骤 2：连接到设备

替换 `<device-ip>` 为实际 IP 地址：

```powershell
adb connect <device-ip>:5555
```

例如：
```powershell
adb connect 192.168.1.105:5555
```

输出：
```
connected to 192.168.1.105:5555
```

**此时可以断开 USB 数据线**（可选但推荐）

### 步骤 3：验证连接

```powershell
adb devices
```

输出示例：
```
List of attached devices
192.168.1.105:5555     device
```

如果显示 `device`，说明连接成功 ✅

---

## 📦 安装 APK

### 使用自动脚本（推荐）

```powershell
install_apk_wifi.bat
```

自动处理所有步骤。

### 或手动安装

```powershell
# Debug 版本
adb install -r build/app/outputs/apk/debug/app-debug.apk

# Release 版本
adb install -r build/app/outputs/apk/release/app-release.apk

# 指定设备
adb -s <device-ip>:5555 install -r <apk-path>
```

参数说明：
- `-r`：覆盖安装（如果已有旧版本）
- 如果有多个设备，指定 `-s <device-ip>:5555`

输出：
```
Success
```

---

## 🚀 启动应用

### 通过 WiFi 启动

```powershell
adb shell am start -n com.example.di_guo_1_hao/.MainActivity
```

或在设备上直接点击应用图标。

---

## 🐛 故障排查

### 问题 1：连接失败

**症状**：`unable to connect to 192.168.1.105:5555`

**原因和解决**：

```powershell
# 1. 检查网络连接
ping 192.168.1.105

# 2. 检查设备是否真的启用了 TCP 模式
adb devices

# 3. 重新启用 TCP 模式
adb tcpip 5555

# 4. 重新连接
adb connect 192.168.1.105:5555

# 5. 如果还是不行，重启设备
```

### 问题 2：安装失败

**症状**：`INSTALL_FAILED_...`

**常见错误和解决**：

```powershell
# 错误：INSTALL_FAILED_VERSION_DOWNGRADE
# 原因：安装的版本比已有的旧
# 解决：
adb uninstall com.example.di_guo_1_hao
adb install app-debug.apk

# 错误：INSTALL_FAILED_INSUFFICIENT_STORAGE
# 原因：设备空间不足
# 解决：
adb shell pm clear com.example.di_guo_1_hao  # 清除应用数据
# 或手动清理设备存储

# 错误：INSTALL_FAILED_INVALID_APK
# 原因：APK 损坏
# 解决：
flutter clean
flutter build apk --debug

# 错误：INSTALL_FAILED_USER_RESTRICTED
# 原因：权限问题
# 解决：
adb shell pm grant com.example.di_guo_1_hao android.permission.INTERNET
```

### 问题 3：连接中断

**症状**：WiFi 连接时断时续

**原因**：网络不稳定或距离太远

**解决**：

```powershell
# 1. 靠近路由器
# 2. 重新连接
adb disconnect 192.168.1.105:5555
adb connect 192.168.1.105:5555

# 3. 或重新启用 TCP 并连接
adb tcpip 5555
adb connect 192.168.1.105:5555
```

### 问题 4：无法获取 IP 地址

**症状**：命令输出为空

**解决**：

```powershell
# 方式 1：手动从设备获取
# 设置 → WiFi → 连接的网络 → 高级 → IP 地址

# 方式 2：使用其他命令
adb shell ip route
adb shell hostname -I

# 方式 3：通过路由器管理界面查看连接的设备
```

---

## ⚡ 快速命令参考

```powershell
# 基础操作
adb devices                                    # 列出设备
adb tcpip 5555                                # 启用 TCP 模式
adb connect <ip>:5555                        # 连接设备
adb disconnect <ip>:5555                     # 断开设备

# 安装和运行
adb install -r <apk-path>                    # 安装 APK
adb uninstall com.example.di_guo_1_hao      # 卸载应用
adb shell am start -n <package>/.MainActivity # 启动应用

# 调试和日志
adb logcat -s flutter                        # 查看日志
adb shell pm clear <package>                 # 清除应用数据
adb shell pm list packages                   # 列出已安装应用

# 文件传输
adb push <local-file> <device-path>         # 上传文件
adb pull <device-path> <local-path>         # 下载文件

# 切换模式
adb usb                                      # 切换回 USB 模式
```

---

## 🛠️ 脚本工具

### 一键安装脚本

```powershell
install_apk_wifi.bat
```

功能：
- 自动启用 TCP 模式
- 自动获取设备 IP
- 自动检测 APK 文件
- 自动安装

### WiFi 设备管理工具

```powershell
wifi_device_manager.bat
```

功能：
- 9 个菜单选项
- 启用 TCP 模式
- 连接 WiFi
- 查看设备
- 安装 APK
- 运行应用
- 查看日志
- 断开连接
- 完整工作流

---

## 📊 对比：USB vs WiFi

| 方面 | USB | WiFi |
|------|-----|------|
| 连接速度 | 快 | 稍慢 |
| 安装速度 | 非常快 | 快 |
| 稳定性 | 很稳定 | 一般 |
| 自由度 | 需要数据线 | 完全无线 |
| 使用场景 | 开发调试 | 演示测试 |

---

## 💡 最佳实践

### 开发阶段

1. USB 连接进行快速开发和调试
2. 每次修改后使用 `flutter run`
3. 查看日志确保没有错误

### 测试阶段

1. WiFi 连接进行无线测试
2. 在不同位置测试网络稳定性
3. 测试 WiFi 切换和网络中断恢复

### 演示阶段

1. WiFi 连接更方便
2. 无需数据线连接
3. 可以移动设备进行演示

---

## 🎯 完整工作流示例

### 场景：开发一个功能并在 WiFi 上测试

```powershell
# 1. USB 连接进行开发
USB 连接设备

# 2. 快速开发循环
修改代码
→ flutter run
→ 查看日志
→ 修改代码
→ 按 'r' 热刷新

# 3. 切换到 WiFi 进行测试
adb tcpip 5555
adb connect 192.168.1.105:5555

# 4. 构建并安装最终版本
flutter build apk --release
adb install -r build/app/outputs/apk/release/app-release.apk

# 5. 启动应用进行最终测试
adb shell am start -n com.example.di_guo_1_hao/.MainActivity

# 6. 查看日志
adb logcat -s flutter

# 7. 完成后断开连接
adb disconnect 192.168.1.105:5555
```

---

## 📝 检查清单

- [ ] 设备通过 USB 连接
- [ ] 设备已启用 USB 调试
- [ ] 设备和电脑在同一 WiFi
- [ ] 已获取设备 IP 地址
- [ ] 已构建 APK 文件
- [ ] 已启用 TCP 模式
- [ ] 已连接到 WiFi
- [ ] 已验证连接
- [ ] 已安装 APK
- [ ] 已在设备上找到应用

---

## 🆘 需要帮助？

### 快速命令

```powershell
# 使用自动脚本（最简单）
install_apk_wifi.bat

# 或使用管理工具（更多选项）
wifi_device_manager.bat

# 或手动命令（最灵活）
adb tcpip 5555
adb connect <device-ip>:5555
adb install -r <apk-path>
```

### 常见问题

查看本文档的"故障排查"部分。

### 获取更多信息

```powershell
# 查看 adb 帮助
adb --help
adb install --help

# 查看 Flutter 文档
flutter doctor
```

---

**最后更新**: 2025-11-22  
**版本**: 1.0  
**状态**: ✅ 生产就绪

---

## 快速总结

```
3 步 WiFi 安装 APK：

1️⃣ 启用 TCP 模式
   adb tcpip 5555

2️⃣ 连接到设备
   adb connect <device-ip>:5555

3️⃣ 安装 APK
   adb install -r <apk-path>
```

**或者直接运行**：`install_apk_wifi.bat` 自动完成！

---
