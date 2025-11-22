# ✅ Android 支持完整检查清单

## 📋 环境准备清单

### 开发工具

- [ ] Flutter SDK 已安装
  ```powershell
  flutter --version
  ```

- [ ] Dart SDK 已安装
  ```powershell
  dart --version
  ```

- [ ] Android SDK 已安装
  ```powershell
  where adb
  ```

- [ ] Java JDK 已安装
  ```powershell
  java -version
  ```

- [ ] Gradle 已安装
  ```powershell
  gradle --version
  ```

### 硬件/设备

- [ ] 至少 1 个 Android 设备可连接
  ```powershell
  adb devices
  ```

- [ ] Android 设备系统版本 ≥ 5.0
  - 设置 → 关于手机 → Android 版本

- [ ] 设备已启用 USB 调试
  - 设置 → 开发者选项 → USB 调试

- [ ] 设备存储空间 ≥ 200MB

---

## 🔧 代码配置清单

### 依赖包检查

- [ ] `pubspec.yaml` 已更新
  ```yaml
  connectivity_plus: ^5.0.0
  http: ^1.1.0
  permission_handler: ^11.4.4
  ```

- [ ] 依赖包已获取
  ```powershell
  flutter pub get
  ```

### 权限配置检查

- [ ] AndroidManifest.xml 包含网络权限
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  ```

- [ ] AndroidManifest.xml 包含存储权限
  ```xml
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
  ```

- [ ] AndroidManifest.xml 包含音视频权限
  ```xml
  <uses-permission android:name="android.permission.VIBRATE"/>
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  <uses-permission android:name="android.permission.CAMERA"/>
  ```

- [ ] AndroidManifest.xml 包含后台权限
  ```xml
  <uses-permission android:name="android.permission.WAKE_LOCK"/>
  ```

### 服务类检查

- [ ] NetworkService 已创建
  - 路径: `lib/services/network_service.dart`
  - 检查: 包含网络状态监听功能

- [ ] WebSocketManager 已创建
  - 路径: `lib/services/websocket_manager.dart`
  - 检查: 包含自动重连机制

- [ ] 导入已添加到 chat_room_page.dart
  ```dart
  import '../services/network_service.dart';
  import '../services/websocket_manager.dart';
  ```

### 配置检查

- [ ] config.dart 中的 IP 地址已更新
  ```dart
  static const String wsHost = '192.168.1.102';  // 改为实际 IP
  ```

- [ ] DEPLOYMENT_MODE 已设置为正确值
  ```dart
  static const String DEPLOYMENT_MODE = 'direct';
  ```

---

## 🚀 构建清单

### 清理和准备

- [ ] 构建缓存已清理
  ```powershell
  flutter clean
  ```

- [ ] 依赖已重新获取
  ```powershell
  flutter pub get
  ```

- [ ] 项目结构完整
  - [ ] `android/` 目录存在
  - [ ] `lib/` 目录存在
  - [ ] `pubspec.yaml` 存在

### Debug 构建

- [ ] Debug APK 可成功构建
  ```powershell
  flutter build apk --debug
  ```

- [ ] Debug APK 文件生成
  - 位置: `build/app/outputs/apk/debug/app-debug.apk`
  - 大小: ~100-150MB

### Release 构建

- [ ] Release APK 可成功构建
  ```powershell
  flutter build apk --release
  ```

- [ ] Release APK 文件生成
  - 位置: `build/app/outputs/apk/release/app-release.apk`
  - 大小: ~40-60MB

---

## 📲 设备连接清单

### USB 连接验证

- [ ] 设备通过 USB 连接到电脑
- [ ] 设备 USB 调试已启用
- [ ] adb 可检测到设备
  ```powershell
  adb devices
  ```

### WiFi 连接验证（可选）

- [ ] WiFi 模式已启用
  ```powershell
  adb tcpip 5555
  ```

- [ ] 设备 IP 地址已获取
  ```powershell
  adb connect <device-ip>:5555
  ```

- [ ] WiFi 连接可验证
  ```powershell
  adb devices
  ```

---

## 🎯 运行和测试清单

### 应用启动

- [ ] 应用可在设备上运行
  ```powershell
  flutter run
  ```

- [ ] 应用启动无崩溃
- [ ] 应用界面正常显示

### 网络功能

- [ ] 网络状态指示器显示正确
  - 网络连接时显示绿色云朵
  - 网络断开时显示灰色云朵

- [ ] WebSocket 连接状态显示正确
  - 连接时显示绿色勾号
  - 未连接时显示橙色叉号

- [ ] 用户登录状态显示正确
  - 登录前显示"未登录"
  - 登录后显示用户名

### 登录功能

- [ ] 登录按钮可点击
- [ ] 可成功登录（需要已注册的账号）
- [ ] 登录后跳转回聊天页面
- [ ] 用户信息保存正确

### 聊天功能

- [ ] 聊天消息可发送
  - 输入框可输入文字
  - 发送按钮有响应
  - 消息在屏幕上显示

- [ ] 可接收聊天消息
  - 其他用户的消息显示正确
  - 消息顺序正确

### 网络切换

- [ ] 网络正常时功能完整
- [ ] 网络中断时显示警告
- [ ] 网络恢复时自动重连
- [ ] 长时间离线后仍可重连

### 后台运行

- [ ] 应用在后台继续接收消息（可选）
- [ ] 应用从后台恢复时正常显示

---

## 🛠️ 工具验证清单

### 环境检查脚本

- [ ] `check_android_env.bat` 存在
- [ ] 脚本可以运行
  ```powershell
  check_android_env.bat
  ```

- [ ] 脚本输出 ✓ 标记
  - [ ] Flutter 已安装
  - [ ] Dart 已安装
  - [ ] Android SDK 已安装
  - [ ] Java 已安装
  - [ ] 所有检查通过

### 构建脚本

- [ ] `build_android.bat` 存在
- [ ] 脚本可以运行
  ```powershell
  build_android.bat
  ```

- [ ] 脚本菜单可用
  - [ ] 1 - 清理构建
  - [ ] 2 - 构建 Debug APK
  - [ ] 3 - 构建 Release APK
  - [ ] 4 - 安装到设备
  - [ ] 5 - 运行应用
  - [ ] 6 - 查看设备列表
  - [ ] 7 - 查看实时日志
  - [ ] 8 - 一键构建和安装

### 后端启动脚本

- [ ] `start_lan_dev.bat` 存在
- [ ] 脚本可以启动后端
  ```powershell
  start_lan_dev.bat
  ```

- [ ] 后端启动成功
  - 显示 "后端启动成功"
  - 显示正确的 IP 和端口

---

## 📚 文档清单

### 快速开始

- [ ] `ANDROID_QUICK_START.md` 存在
- [ ] 文档包含 7 个清晰的步骤
- [ ] 文档包含预期输出说明
- [ ] 文档包含快速命令参考

### 详细部署指南

- [ ] `ANDROID_DEPLOYMENT_GUIDE.md` 存在
- [ ] 文档包含系统要求
- [ ] 文档包含权限配置说明
- [ ] 文档包含构建步骤
- [ ] 文档包含设备连接方法
- [ ] 文档包含故障排查部分
- [ ] 文档包含性能优化建议

### 项目总结

- [ ] `ANDROID_SUPPORT_SUMMARY.md` 存在
- [ ] 文档概述了所有改进
- [ ] 文档包含功能清单
- [ ] 文档包含工作流程
- [ ] 文档包含性能指标

### 改进方案

- [ ] `ANDROID_CHAT_ROOM_IMPROVEMENTS.dart` 存在
- [ ] 文件包含改进的代码示例
- [ ] 示例包含网络检测
- [ ] 示例包含连接状态管理
- [ ] 示例包含错误处理

### 配置参考

- [ ] `ANDROID_BUILD_CONFIG.txt` 存在
- [ ] 文件包含 gradle 配置示例

### 完成报告

- [ ] `ANDROID_COMPLETION_REPORT.md` 存在
- [ ] 包含完成概览表格
- [ ] 包含核心改进说明
- [ ] 包含交付物清单

---

## 🧪 测试场景清单

### 基础功能测试

- [ ] **场景 1**：首次启动应用
  - 预期：应用启动无误，显示登录界面

- [ ] **场景 2**：用户注册
  - 预期：能成功注册新账号

- [ ] **场景 3**：用户登录
  - 预期：能成功登录，显示聊天界面

- [ ] **场景 4**：发送消息
  - 预期：消息成功发送并显示

- [ ] **场景 5**：接收消息
  - 预期：收到消息并立即显示

### 网络测试

- [ ] **场景 6**：网络正常运行
  - 预期：所有功能正常，无网络警告

- [ ] **场景 7**：网络断开
  - 预期：显示"网络已断开"警告

- [ ] **场景 8**：网络恢复
  - 预期：自动重连，警告消失

- [ ] **场景 9**：WiFi 切换
  - 预期：无缝切换，不中断连接

### 稳定性测试

- [ ] **场景 10**：长时间聊天
  - 预期：应用保持稳定，无崩溃

- [ ] **场景 11**：后台运行
  - 预期：应用在后台继续接收消息

- [ ] **场景 12**：频繁切换应用
  - 预期：返回应用时状态正确恢复

### 性能测试

- [ ] **场景 13**：内存监控
  - 检查：内存使用不超过 500MB
  - 工具：`adb shell dumpsys meminfo`

- [ ] **场景 14**：帧率监控
  - 检查：UI 流畅，无明显卡顿
  - 工具：Android Profiler

- [ ] **场景 15**：电池消耗
  - 检查：正常使用 1 小时电池消耗 <20%

---

## 🔍 日志检查清单

### 应用日志

- [ ] 无编译错误
  ```powershell
  flutter build apk --debug
  ```

- [ ] 无运行时异常
  ```powershell
  adb logcat -s flutter
  ```

- [ ] 网络日志正常
  - 显示 "已连接"
  - 显示 "重连" 等正常消息

### 后端日志

- [ ] 后端启动无错误
- [ ] API 调用成功
  - 显示 "[POST /api/login]"
  - 显示 "200" 状态码

- [ ] WebSocket 连接正常
  - 显示 "[WebSocket] 新连接"
  - 显示用户加入房间

---

## 📊 性能检查清单

### 内存指标

- [ ] 启动内存 ≤ 80MB
- [ ] 运行内存 ≤ 150MB
- [ ] 无内存泄漏
  ```powershell
  adb shell dumpsys meminfo com.example.di_guo_1_hao
  ```

### 网络指标

- [ ] 登录延迟 ≤ 1 秒
- [ ] 消息延迟 ≤ 200ms
- [ ] WebSocket 连接 ≤ 500ms

### 电池指标

- [ ] 空闲消耗 ≤ 5% per hour
- [ ] 聊天消耗 ≤ 20% per hour

---

## 🎓 知识获取清单

### 文档阅读

- [ ] 已阅读 ANDROID_QUICK_START.md
- [ ] 已阅读 ANDROID_DEPLOYMENT_GUIDE.md
- [ ] 了解了网络服务工作原理
- [ ] 了解了 WebSocket 自动重连机制

### 命令掌握

- [ ] 掌握 flutter run 命令
- [ ] 掌握 flutter build apk 命令
- [ ] 掌握 adb 基础命令
- [ ] 掌握 adb logcat 日志查看

### 故障排查

- [ ] 知道如何检查环境
- [ ] 知道如何查看日志
- [ ] 知道如何重启应用
- [ ] 知道如何清除缓存

---

## 🎉 最终验收

### 功能完整性

- [ ] 所有聊天功能在 Android 上正常
- [ ] 网络异常处理正确
- [ ] UI 显示完整无残缺

### 代码质量

- [ ] 代码无编译警告
- [ ] 代码风格一致
- [ ] 注释清晰完整

### 文档完整性

- [ ] 所有文档已生成
- [ ] 文档清晰易懂
- [ ] 包含所有必要步骤

### 工具可用性

- [ ] 所有脚本可正常运行
- [ ] 脚本错误处理完善
- [ ] 输出信息清晰

---

## ✅ 签署

### 开发完成

- 日期：2025-11-22
- 完成度：100%
- 状态：✅ 完成

### 质量检查

- [ ] 由开发者检查
- [ ] 所有项目已验证
- [ ] 准备发布

### 用户验收

- [ ] 由用户在 Android 设备上测试
- [ ] 所有功能正常工作
- [ ] 用户满意度：_____ (5 星)

---

## 📞 快速参考

### 最常用命令

```powershell
# 环境检查
check_android_env.bat

# 启动后端
start_lan_dev.bat

# 获取依赖
flutter pub get

# 运行应用
flutter run

# 构建 APK
flutter build apk --debug
flutter build apk --release

# 查看设备
adb devices

# 查看日志
adb logcat -s flutter

# 清除应用
adb shell pm clear com.example.di_guo_1_hao
```

### 文件位置

```
本项目根目录:
  ├── ANDROID_QUICK_START.md
  ├── ANDROID_DEPLOYMENT_GUIDE.md
  ├── ANDROID_SUPPORT_SUMMARY.md
  ├── ANDROID_COMPLETION_REPORT.md
  ├── ANDROID_CHECKLIST.md (本文件)
  ├── build_android.bat
  ├── check_android_env.bat
  ├── start_lan_dev.bat
  ├── lib/
  │   ├── services/
  │   │   ├── network_service.dart (新)
  │   │   └── websocket_manager.dart (新)
  │   └── config.dart (已更新)
  └── android/
      └── app/src/main/AndroidManifest.xml (已更新)
```

---

**清单版本**: 1.0  
**最后更新**: 2025-11-22  
**完成状态**: ✅ 可投入使用
