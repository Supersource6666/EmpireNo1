# P2P 聊天系统配置快速参考

## 一. 服务器配置 (config.dart)

### 当前配置
```dart
class AppConfig {
  // LAN 模式 (局域网)
  static const String wsHost = '192.168.1.102';  // ← 修改为你的服务器IP
  static const int wsPort = 3000;
  static const String wsUrl = 'ws://192.168.1.102:3000';  // ← 修改为 ws://你的IP:3000
  
  // 远程模式 (公网)
  static const String wssUrl = 'wss://your-domain.com:3000';  // ← 修改为你的域名
}
```

### 如何找到正确的IP地址

**Windows:**
```powershell
ipconfig
# 查看 IPv4 地址 (通常是 192.168.x.x 或 10.x.x.x)
```

**Linux/Mac:**
```bash
ifconfig
# 或
ip addr
```

**Android/iOS:**
- 设置 → Wi-Fi → 选择连接的网络 → 查看详情 → IP 地址

## 二. 后端启动

### 前提条件
- 安装 Node.js (v14+)
- 安装 SQLite3

### 启动步骤
```bash
# 1. 进入后端目录
cd backend/

# 2. 安装依赖
npm install

# 3. 启动服务器
node server.js
```

### 预期输出
```
[服务器启动] 准备接收连接
WebSocket 服务器运行在 ws://0.0.0.0:3000
[Express] REST API 在 http://0.0.0.0:3000/api
```

### 验证连接
```bash
# 从另一台设备测试
curl http://<server-ip>:3000/api/health
# 应该返回 {"status": "ok"}
```

## 三. 前端配置

### 修改步骤
1. 打开 `lib/config.dart`
2. 修改 `wsHost` 为服务器的局域网IP
3. 如果使用非标准端口，也修改 `wsPort`

### 示例配置
```dart
// 如果服务器在 192.168.1.50
static const String wsHost = '192.168.1.50';
static const String wsUrl = 'ws://192.168.1.50:3000';
```

## 四. 运行应用

### 在特定设备上运行
```bash
# 列出可用设备
flutter devices

# 在设备 ID 为 "emulator-5554" 的设备上运行
flutter run -d emulator-5554
```

### 在多个设备上测试
```bash
# 终端1 - 设备A
flutter run -d device-a-id

# 终端2 - 设备B
flutter run -d device-b-id
```

## 五. 测试聊天功能

### 第一步：连接验证
1. 启动应用后，查看 AppBar 中的连接状态
2. 绿色 = 已连接 ✅
3. 红色 = 未连接 ❌

### 第二步：发送消息
1. 在设备A上输入消息
2. 点击发送按钮
3. 在设备B上应该立即显示消息

### 第三步：发送图像
1. 点击图像按钮
2. 选择照片
3. 等待上传完成（显示成功提示）
4. 对方应该接收到图像

## 六. 常见问题快速修复

### ❌ 连接失败（红色离线）

**检查清单：**
- [ ] 后端服务器是否运行？ `netstat -an | grep 3000`
- [ ] IP地址是否正确？ `ipconfig` 确认
- [ ] 防火墙是否阻止？ 关闭或允许3000端口
- [ ] 网络是否相同？ 两个设备是否在同一WiFi上

**快速修复：**
```bash
# 方案A：重启服务器
# Ctrl+C 停止服务器
node server.js

# 方案B：检查防火墙 (Windows)
netsh advfirewall firewall add rule name="Allow Port 3000" dir=in action=allow protocol=tcp localport=3000

# 方案C：检查网络连通性
ping <server-ip>
```

### ❌ 消息发送失败

**日志查看：**
```bash
# Flutter 日志
flutter logs -f | grep "\[P2PChat\]"

# 服务器日志
# 查看启动 server.js 时的输出
# 应该看到 [broadcast] 标记的消息转发日志
```

**常见原因：**
- 房间ID不匹配 → 检查roomId参数
- userId不正确 → 确保myId和peerId不同
- 消息格式错误 → 查看消息格式JSON

### ❌ 消息重复显示

**原因：** 后端广播给所有用户，包括发送者自己

**解决：** 已自动实现过滤
- 前端检查 `msg['from'] == myId`
- 自己的消息直接返回，不进行额外处理
- 如果仍然重复，检查是否禁用了自过滤逻辑

## 七. 性能调优

### 降低消息延迟
```dart
// 在 ChatClient 类中
static const int RECONNECT_DELAY_MS = 1000;  // 减少延迟时间
```

### 提高稳定性
```dart
// 在 ChatClient 类中
static const int MAX_RECONNECT_ATTEMPTS = 10;  // 增加重连次数
```

### 优化图像传输
```dart
// 在 _sendImage 方法中
int quality = 50;  // 降低质量（范围1-100）加快速度
```

## 八. 安全建议

### LAN 环境
- ✅ 使用 `ws://` (不加密)，因为网络是可信的
- ✅ 限制连接到内网IP
- ⚠️ 不建议直接暴露到互联网

### 远程访问
- 🔐 配置 `wss://` (加密WebSocket)
- 🔐 添加认证令牌验证
- 🔐 实施消息加密

### 数据库安全
- 定期备份SQLite数据库
- 限制数据库文件权限 (chmod 600)
- 对敏感信息进行加密

## 九. 调试命令

### Flutter 调试
```bash
# 查看实时日志（包含所有print输出）
flutter logs -f

# 仅查看P2P聊天相关日志
flutter logs -f | findstr "P2PChat"  # Windows
flutter logs -f | grep "P2PChat"      # Linux/Mac

# 连接到特定设备
flutter attach -d <device-id>
```

### Node.js 调试
```bash
# 启用详细日志
DEBUG=* node server.js

# 查看进程信息
lsof -i :3000      # Linux/Mac
netstat -ano | findstr :3000  # Windows
```

### WebSocket 连接测试
```bash
# 使用 wscat 工具
npm install -g wscat
wscat -c ws://192.168.1.102:3000

# 发送测试消息
{"type":"join","room":"test","from":"user1"}
```

## 十. 生产环境检查清单

- [ ] 更新所有IP地址到实际值
- [ ] 配置SSL/TLS证书（if wss://)
- [ ] 启用数据库备份
- [ ] 配置日志轮转
- [ ] 设置监控告警
- [ ] 文档化部署步骤
- [ ] 测试故障转移
- [ ] 进行压力测试

---

**快速开始总结：**
1. 修改 `config.dart` 中的 IP 地址
2. 运行 `node server.js`
3. 运行 `flutter run`
4. 在多个设备上测试
5. 验证消息实时显示
