# P2P LAN 聊天指南

## 概述
这个应用程序支持在局域网(LAN)内进行实时P2P(点对点)聊天。用户可以在同一局域网内的不同设备上进行文本和图像通信。

## 系统架构

### 组件
1. **Flutter 前端** (`p2p_chat_page.dart`)
   - 用户界面：消息显示、文本输入、图像选择
   - WebSocket 客户端：与后端服务器通信
   - 连接状态管理：显示连接状态指示器
   - 消息缓存：显示聊天历史

2. **Node.js 后端** (`server.js`)
   - WebSocket 服务器：在端口3000监听
   - 消息转发：在聊天室中广播消息
   - 消息存储：使用SQLite3数据库持久化消息
   - REST API：提供历史消息查询接口

### 网络架构
```
设备A (192.168.1.100)         设备B (192.168.1.102)
    |                              |
    +------------- 局域网 -----------+
         |
    WebSocket 服务器 (192.168.1.102:3000)
         |
    SQLite3 数据库 (消息历史)
```

## 配置指南

### 1. 服务器配置 (config.dart)

```dart
class AppConfig {
  // LAN 模式：使用 ws:// (不安全) 和局域网IP
  static const String wsHost = '192.168.1.102';  // 服务器主机IP
  static const int wsPort = 3000;                // 服务器端口
  static const String wsUrl = 'ws://192.168.1.102:3000';
  
  // 远程模式：使用 wss:// (安全) 和域名/公网IP
  static const String wssUrl = 'wss://your-domain.com:3000';
}
```

### 2. 后端服务器配置 (server.js)

```javascript
const PORT = 3000;
const server = require('http').createServer();
const wss = new WebSocket.Server({ server });

server.listen(PORT, () => {
  console.log(`WebSocket 服务器运行在 ws://0.0.0.0:${PORT}`);
});
```

## 使用说明

### 第一步：启动后端服务
```bash
cd backend
npm install
node server.js
```

输出应该包含：
```
WebSocket 服务器运行在 ws://0.0.0.0:3000
[服务器启动] 准备接收连接
```

### 第二步：确保网络连接
- 所有设备连接到同一个WiFi或有线网络
- 验证主机IP地址 (Windows: `ipconfig`, Linux/Mac: `ifconfig`)
- 在 `config.dart` 中更新 `wsHost` 为实际的服务器IP

### 第三步：运行应用
```bash
flutter run
# 或在特定设备上
flutter run -d <device-id>
```

### 第四步：进行P2P聊天
1. 输入消息并点击发送按钮
2. 查看顶部连接状态指示器（绿色=已连接，红色=未连接）
3. 消息会实时显示在双方的屏幕上
4. 可以通过图像按钮发送照片

## 功能特性

### ✅ 已实现的功能
- **实时文本消息**：使用WebSocket进行低延迟通信
- **图像发送**：支持JPEG/PNG格式，自动压缩
- **消息历史**：通过REST API从数据库检索旧消息
- **连接状态指示**：在AppBar中显示连接状态
- **自动重连**：连接失败时自动尝试重新连接（最多5次）
- **消息过滤**：自动过滤并隐藏自己发送的重复消息
- **LAN/远程双模式**：支持wsMode参数切换

### 🚀 架构改进

#### 1. WebSocket 连接管理
- **正确的回调绑定顺序**：`_onMessage` 在 `connect()` 前设置
- **Lambda 包装**：`stream.listen((msg) => _onMessage?.call(msg))`确保动态回调更新
- **连接状态追踪**：`_onConnectionStateChanged` 回调用于UI更新

#### 2. 消息处理流程
```
用户输入 → 本地渲染 → WebSocket 发送 → 后端广播 → 对方接收 → onMessage回调 → 对方渲染
```

#### 3. 自动重连机制
```
连接失败 → 等待2秒 → 自动重连
             ↓
重连5次后 → 放弃 → 显示离线状态 → 等待用户手动重试
```

#### 4. 自过滤机制
- 后端广播所有消息（包括发送者自己）
- 前端在 `onMessage` 中检查 `msg.from == myId`
- 如果是自己的消息则跳过，避免重复显示

## 消息格式

### 文本消息
```json
{
  "type": "text",
  "room": "room123",
  "from": "user1",
  "to": "user2",
  "body": "消息内容",
  "ts": "2024-01-01T12:00:00.000Z"
}
```

### 图像消息头
```json
{
  "type": "image_header",
  "room": "room123",
  "from": "user1",
  "imageId": "uuid-v4",
  "format": "jpeg",
  "size": 102400,
  "chunks": 2,
  "ts": "2024-01-01T12:00:00.000Z"
}
```

### 图像分片
```json
{
  "type": "image_chunk",
  "imageId": "uuid-v4",
  "index": 0,
  "chunks": 2,
  "room": "room123",
  "from": "user1"
}
```

## 故障排除

### 问题1：连接失败（显示红色离线状态）
**原因可能**：
- 服务器未运行
- 防火墙阻止了3000端口
- IP地址配置错误
- 设备不在同一网络

**解决方案**：
```bash
# 检查服务器是否运行
netstat -an | grep 3000

# 在另一台设备上测试连接
telnet <server-ip> 3000

# 检查防火墙（Windows）
netsh advfirewall firewall add rule name="Allow Port 3000" dir=in action=allow protocol=tcp localport=3000
```

### 问题2：消息发送成功但对方未收到
**原因可能**：
- 房间ID不匹配
- onMessage 回调未正确绑定
- 消息被自过滤机制误过滤

**调试**：
- 查看控制台输出的 `[P2PChat][onMessage]` 日志
- 检查 `from` 和 `myId` 是否正确
- 验证 `room` 参数一致性

### 问题3：自发送消息重复显示
**原因**：后端广播消息给所有用户（包括发送者）

**解决方案**：已实现的自过滤机制
- 前端检查 `msg['from'] == widget.myId`
- 自己的消息本地渲染后直接返回，不再处理后端广播

### 问题4：连接不稳定，频繁断开
**原因可能**：
- 网络不稳定
- 设备进入省电模式
- 路由器超时设置

**解决方案**：
- 检查网络信号强度
- 禁用设备省电模式
- 增加 `RECONNECT_DELAY_MS` 的值
- 增加 `MAX_RECONNECT_ATTEMPTS` 的重连次数

## 性能指标

| 指标 | 值 |
|------|-----|
| 消息延迟 | <100ms (LAN) |
| 最大图像大小 | 无限制（自动分片，64KB/块） |
| 图像发送速度 | ~5KB/ms (取决于网络) |
| 最大同时连接数 | 取决于服务器内存 |
| 消息历史查询 | <1s (本地数据库) |

## 安全建议

### 针对LAN环境
- ✅ LAN内通信无需加密（`ws://`）
- ✅ 使用内网IP（192.168.x.x）
- ⚠️ 不建议暴露到公网

### 针对远程通信
- 使用 `wss://` (WebSocket Secure)
- 配置 SSL/TLS 证书
- 添加身份验证机制
- 实施消息加密

## 开发和调试

### 启用详细日志
所有关键操作都包含 `print()` 调试日志：
```
[P2PChat][initState] 初始化
[P2PChat][_initClient] 创建客户端
[P2PChat][onMessage] 接收消息
[ChatClient][connect] 连接WebSocket
[ChatClient][_reconnect] 自动重连
```

### 在Flutter中查看日志
```bash
flutter logs -f | grep "\[P2PChat\]"
```

### 在Node.js中查看日志
```bash
node server.js 2>&1 | tee server.log
```

## 扩展功能建议

1. **消息加密**：使用 `cryptography` 包加密文本消息
2. **离线消息**：实现消息队列，用户离线时存储消息
3. **群组聊天**：扩展到多人聊天室
4. **消息搜索**：添加数据库查询功能
5. **消息已读状态**：追踪消息读取状态
6. **用户状态**：显示用户在线/离线/输入中状态
7. **通知**：添加消息通知提醒

## 参考资源

- Flutter WebSocket: https://pub.dev/packages/web_socket_channel
- Node.js WebSocket: https://github.com/websockets/ws
- 网络编程最佳实践: https://developers.google.com/speed/webp/faq

---

**最后更新**: 2024-01-15
**版本**: 1.0
