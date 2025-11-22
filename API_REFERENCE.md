# P2P 聊天系统 API 参考

## WebSocket 消息格式

### 1. 加入房间 (join)

**方向**: 客户端 → 服务器

**格式**:
```json
{
  "type": "join",
  "room": "room123",
  "from": "user1"
}
```

**字段说明**:
- `type`: 固定值 "join"
- `room`: 聊天室ID (两个用户应使用相同的ID)
- `from`: 用户ID

**服务器响应**: 不返回响应，但会在房间中记录用户

**示例**:
```javascript
client._ws.sink.add(jsonEncode({
  "type": "join",
  "room": "user1-user2",
  "from": "user1"
}));
```

---

### 2. 发送文本消息 (text)

**方向**: 客户端 → 服务器 → 所有客户端

**格式**:
```json
{
  "type": "text",
  "room": "room123",
  "from": "user1",
  "to": "user2",
  "body": "消息内容",
  "ts": "2024-01-15T12:00:00.000Z"
}
```

**字段说明**:
- `type`: 固定值 "text" 或 "message"
- `room`: 聊天室ID
- `from`: 发送者用户ID
- `to`: 接收者用户ID (可选，用于数据库记录)
- `body`: 消息内容
- `ts`: ISO8601 格式的时间戳

**服务器处理**:
1. 验证消息格式
2. 广播给房间内所有用户
3. 保存到数据库 (如果有 `to` 字段)

**示例**:
```dart
final msg = {
  "type": "text",
  "room": "room123",
  "from": "user1",
  "to": "user2",
  "body": "你好！",
  "ts": DateTime.now().toIso8601String()
};
_ws.sink.add(jsonEncode(msg));
```

---

### 3. 发送图像消息 (image_header + image_chunk + image_end)

#### 3.1 图像头部 (image_header)

**方向**: 客户端 → 服务器

**格式**:
```json
{
  "type": "image_header",
  "room": "room123",
  "from": "user1",
  "imageId": "550e8400-e29b-41d4-a716-446655440000",
  "format": "jpeg",
  "size": 102400,
  "chunks": 2,
  "ts": "2024-01-15T12:00:00.000Z"
}
```

**字段说明**:
- `imageId`: UUID v4，用于识别图像
- `format`: 图像格式 ("jpeg", "png")
- `size`: 总字节数
- `chunks`: 总分片数

#### 3.2 图像分片 (image_chunk)

**方向**: 客户端 → 服务器

**格式**: 两条消息
```json
{
  "type": "image_chunk",
  "imageId": "550e8400-e29b-41d4-a716-446655440000",
  "index": 0,
  "chunks": 2,
  "room": "room123",
  "from": "user1"
}
```
后跟二进制数据 (64KB)

**字段说明**:
- `index`: 分片序号 (0开始)
- `chunks`: 总分片数
- 二进制数据: 图像分片内容

#### 3.3 图像完成 (image_end)

**方向**: 客户端 → 服务器

**格式**:
```json
{
  "type": "image_end",
  "imageId": "550e8400-e29b-41d4-a716-446655440000",
  "room": "room123",
  "from": "user1",
  "ts": "2024-01-15T12:00:00.000Z"
}
```

**完整示例**:
```dart
// 1. 发送头部
_ws.sink.add(jsonEncode({
  "type": "image_header",
  "room": "room123",
  "from": "user1",
  "imageId": "image-uuid",
  "format": "jpeg",
  "size": 102400,
  "chunks": 2,
  "ts": DateTime.now().toIso8601String()
}));

// 2. 发送分片
for (int i = 0; i < 2; i++) {
  _ws.sink.add(jsonEncode({
    "type": "image_chunk",
    "imageId": "image-uuid",
    "index": i,
    "chunks": 2,
    "room": "room123",
    "from": "user1"
  }));
  _ws.sink.add(imageChunkBytes);
}

// 3. 发送完成消息
_ws.sink.add(jsonEncode({
  "type": "image_end",
  "imageId": "image-uuid",
  "room": "room123",
  "from": "user1",
  "ts": DateTime.now().toIso8601String()
}));
```

---

## REST API 端点

### 1. 健康检查

**请求**:
```http
GET /api/health
```

**响应**:
```json
{
  "status": "ok"
}
```

**HTTP 状态**: 200 OK

**用途**: 检查服务器是否运行

**示例**:
```bash
curl http://192.168.1.102:3000/api/health
```

---

### 2. 获取消息历史

**请求**:
```http
GET /api/history?user1=user1&user2=user2
```

**查询参数**:
- `user1`: 第一个用户ID
- `user2`: 第二个用户ID

**响应**:
```json
{
  "success": true,
  "messages": [
    {
      "id": 1,
      "from_user": "user1",
      "to_user": "user2",
      "body": "你好",
      "ts": "2024-01-15T12:00:00.000Z"
    },
    {
      "id": 2,
      "from_user": "user2",
      "to_user": "user1",
      "body": "你好啊",
      "ts": "2024-01-15T12:00:05.000Z"
    }
  ]
}
```

**HTTP 状态**: 200 OK (成功), 500 Internal Server Error (失败)

**用途**: 加载两个用户之间的聊天历史

**示例**:
```bash
curl "http://192.168.1.102:3000/api/history?user1=user1&user2=user2"
```

**Dart 示例**:
```dart
final url = Uri.parse('http://192.168.1.102:3000/api/history?user1=user1&user2=user2');
final response = await http.get(url);
final data = jsonDecode(response.body);
```

---

## WebSocket 事件回调

### ChatClient 回调

#### _onMessage 回调

**触发**: 收到任何 WebSocket 消息

**参数**: `dynamic data` - 原始消息数据

**类型**: 字符串 (JSON 编码)

**用法**:
```dart
client._onMessage = (data) {
  try {
    final obj = jsonDecode(data);
    print('收到消息: $obj');
  } catch (e) {
    print('解码失败: $e');
  }
};
```

#### _onConnectionStateChanged 回调

**触发**: 连接状态变化

**参数**: `bool isConnected`
- `true`: 已连接
- `false`: 未连接/断开

**用法**:
```dart
client._onConnectionStateChanged = (isConnected) {
  setState(() {
    _connected = isConnected;
  });
};
```

---

## 错误处理

### WebSocket 错误

```dart
// 连接错误
[ChatClient][connect][ERROR] 连接失败: SocketException: ...

// 消息解码错误
[P2PChat][onMessage][ERROR] 解码消息异常: FormatException: ...
```

### HTTP 错误

```dart
// API 调用失败
try {
  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('API 错误: ${response.statusCode}');
  }
} catch (e) {
  print('请求失败: $e');
}
```

---

## 数据库架构

### messages 表

```sql
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_user TEXT NOT NULL,
  to_user TEXT NOT NULL,
  body TEXT NOT NULL,
  ts DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_from_to ON messages(from_user, to_user);
CREATE INDEX idx_ts ON messages(ts);
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| from_user | TEXT | 发送者用户ID |
| to_user | TEXT | 接收者用户ID |
| body | TEXT | 消息内容 |
| ts | DATETIME | 时间戳 |

### 查询示例

```sql
-- 获取两个用户的所有消息
SELECT * FROM messages 
WHERE (from_user = 'user1' AND to_user = 'user2')
   OR (from_user = 'user2' AND to_user = 'user1')
ORDER BY ts ASC;

-- 统计消息数
SELECT COUNT(*) FROM messages 
WHERE from_user = 'user1' AND to_user = 'user2';

-- 获取最近的消息
SELECT * FROM messages 
ORDER BY ts DESC 
LIMIT 50;
```

---

## 配置参数

### 应用配置 (config.dart)

```dart
class AppConfig {
  // 服务器地址
  static const String wsHost = '192.168.1.102';      // WebSocket 主机
  static const int wsPort = 3000;                    // WebSocket 端口
  static const String wsUrl = 'ws://192.168.1.102:3000';
  
  // 远程部署
  static const String wssUrl = 'wss://your-domain.com:3000';
}
```

### 客户端参数 (ChatClient)

```dart
class ChatClient {
  static const int CHUNK_SIZE = 64 * 1024;           // 图像分片大小
  static const int MAX_RECONNECT_ATTEMPTS = 5;       // 最大重连次数
  static const int RECONNECT_DELAY_MS = 2000;        // 重连延迟 (毫秒)
}
```

### 服务器参数 (server.js)

```javascript
const PORT = 3000;                                   // 监听端口
const MAX_CONNECTIONS = 10000;                       // 最大连接数
```

---

## 类型定义

### 消息对象 (Dart)

```dart
// 文本消息
Map<String, dynamic> message = {
  "type": "text",
  "text": "消息内容",
  "isMe": true,
  "from": "user1",
  "ts": "2024-01-15T12:00:00.000Z"
};

// 图像消息
Map<String, dynamic> imageMessage = {
  "type": "image",
  "path": "/path/to/image.jpg",
  "isMe": true,
};
```

### 房间信息

```javascript
// 服务器端房间结构
rooms = {
  "room123": {
    "user1": <WebSocket>,
    "user2": <WebSocket>
  }
};

// 用户套接字映射
userSockets = {
  "user1": <WebSocket>,
  "user2": <WebSocket>
};
```

---

## 日志格式

### 前端日志

```
[P2PChat][initState] 初始化状态
[P2PChat][_initClient] 创建客户端
[ChatClient][connect] 连接状态
[P2PChat][onMessage] 消息接收
[P2PChat][build] UI 构建
```

### 后端日志

```
[服务器启动] 准备接收连接
[用户连接] 新WebSocket连接
[加入房间] 用户加入指定房间
[接收消息] 收到消息类型
[广播] 消息转发给房间用户
```

---

## 性能指标

### 消息吞吐量

| 场景 | 吞吐量 | 延迟 |
|------|--------|------|
| 文本消息 | 1000 msg/s | <100ms |
| 图像上传 | ~5MB/s | ~1s/10MB |
| 历史查询 | <1s | 取决于消息数 |

### 连接管理

| 指标 | 值 |
|------|-----|
| 连接建立时间 | ~500ms |
| 心跳间隔 | 30s |
| 重连延迟 | 2s |
| 最大重试次数 | 5 |

---

## 故障恢复

### 自动重连机制

```
连接失败
    ↓
记录尝试次数 (_reconnectAttempts++)
    ↓
检查: _reconnectAttempts < MAX_RECONNECT_ATTEMPTS?
  是 → 等待 RECONNECT_DELAY_MS → 重新连接
  否 → 放弃并通知UI
```

### 消息恢复

```
发送失败
    ↓
捕获异常
    ↓
显示错误提示
    ↓
触发自动重连
    ↓
重连成功 → 可重试发送
```

---

## 常见集成场景

### 场景 1: 初始化聊天

```dart
// 1. 创建客户端
final client = ChatClient(
  userId: "user1",
  roomId: "room123",
  peerId: "user2"
);

// 2. 设置回调
client._onMessage = (data) { /* 处理消息 */ };

// 3. 连接
await client.connect();

// 4. 加载历史
final history = await _loadHistory();
```

### 场景 2: 发送消息流程

```dart
// 1. 获取用户输入
final text = _controller.text;

// 2. 本地渲染
setState(() {
  messages.add({"text": text, "isMe": true});
});

// 3. 通过WebSocket发送
await client.sendText(text);

// 4. 错误处理
// 自动通过 onMessage 回调接收回显
```

### 场景 3: 处理接收消息

```dart
client._onMessage = (data) {
  final obj = jsonDecode(data);
  
  // 过滤自消息
  if (obj['from'] == userId) return;
  
  // 验证房间
  if (obj['room'] != roomId) return;
  
  // 渲染消息
  setState(() {
    messages.add({
      "text": obj['body'],
      "isMe": false,
      "from": obj['from']
    });
  });
};
```

---

## 调试技巧

### 启用详细日志

```bash
# Flutter 日志
flutter logs -f

# 过滤特定模块
flutter logs -f | grep "\[P2PChat\]"
flutter logs -f | grep "\[ChatClient\]"

# 后端日志
DEBUG=* node server.js
```

### 使用 wscat 测试

```bash
# 安装
npm install -g wscat

# 连接到服务器
wscat -c ws://192.168.1.102:3000

# 发送测试消息
{"type":"join","room":"test","from":"debug"}
{"type":"text","room":"test","from":"debug","body":"test","ts":"2024-01-15T12:00:00Z"}
```

### 数据库查询

```bash
# 进入SQLite shell
sqlite3 backend/messages.db

# 查看所有消息
SELECT * FROM messages;

# 统计消息
SELECT COUNT(*) FROM messages;

# 导出为CSV
.mode csv
.output messages.csv
SELECT * FROM messages;
```

---

## 版本信息

| 组件 | 版本 |
|------|------|
| Flutter | 3.0+ |
| Dart | 3.0+ |
| Node.js | 14.0+ |
| web_socket_channel | 2.4.0+ |
| ws (npm) | 8.0.0+ |

---

**API 版本**: 1.0  
**最后更新**: 2024-01-15
