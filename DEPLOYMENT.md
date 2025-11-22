# P2P 聊天系统部署指南

## 目录结构

```
delicious_food_selector/
├── lib/
│   ├── pages/
│   │   └── p2p_chat_page.dart          # P2P 聊天页面 (Flutter)
│   └── config.dart                      # 应用配置
├── backend/
│   ├── server.js                        # WebSocket 服务器
│   ├── package.json                     # Node.js 依赖
│   └── messages.db                      # SQLite 数据库
├── LAN_CHAT_GUIDE.md                    # LAN 聊天详细指南
├── QUICK_START.md                       # 快速开始指南
├── diagnose.sh                          # Linux/Mac 诊断脚本
├── diagnose.bat                         # Windows 诊断脚本
└── DEPLOYMENT.md                        # 本文件

```

## 环境要求

### 前端 (Flutter)
- Flutter SDK 3.0+
- Dart 3.0+
- Android SDK (API 21+) 或 iOS 11.0+
- 或 web 支持

### 后端 (Node.js)
- Node.js 14.0+ (推荐 16+)
- npm 6.0+
- SQLite3

## 完整部署步骤

### A. 准备阶段

#### 1. 确定网络拓扑
```
决定是否使用:
├── LAN 模式 (ws://, 局域网, 快速稳定)
└── 远程模式 (wss://, 互联网, 需要域名和证书)
```

#### 2. 获取服务器 IP 地址
```bash
# Windows
ipconfig

# Linux/Mac
ifconfig
或
ip addr
```

记录下形如 `192.168.x.x` 或 `10.x.x.x` 的内网 IP

### B. 后端部署

#### 1. 安装依赖
```bash
cd backend
npm install
```

#### 2. 验证 package.json
```json
{
  "name": "p2p-chat-server",
  "version": "1.0.0",
  "description": "P2P Chat Server",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "ws": "^8.0.0",
    "sqlite3": "^5.0.0"
  }
}
```

#### 3. 启动服务器
```bash
node server.js
```

**预期输出：**
```
[服务器启动] 准备接收连接
WebSocket 服务器运行在 ws://0.0.0.0:3000
```

#### 4. 验证服务可访问性
```bash
# 本地测试
curl http://localhost:3000/api/health

# 远程测试 (从另一设备)
curl http://<server-ip>:3000/api/health
```

### C. 前端配置

#### 1. 更新 config.dart
```dart
// lib/config.dart
class AppConfig {
  static const String wsHost = '192.168.1.102';  // ← 修改为实际服务器IP
  static const int wsPort = 3000;
  static const String wsUrl = 'ws://192.168.1.102:3000';  // ← 同步修改
  
  // 仅在使用远程模式时配置
  static const String wssUrl = 'wss://your-domain.com:3000';
}
```

#### 2. 编译验证
```bash
flutter pub get
flutter analyze lib/pages/p2p_chat_page.dart
```

### D. 前端部署

#### 1. 在 Android 上部署
```bash
flutter run -d <android-device-id>
```

#### 2. 在 iOS 上部署
```bash
flutter run -d <ios-device-id>
```

#### 3. 在 Web 上部署
```bash
flutter run -d chrome
# 或
flutter run -d firefox
```

### E. 测试阶段

#### 1. 单设备测试
- [ ] 启动应用
- [ ] 检查连接状态 (绿色 = 已连接)
- [ ] 发送测试消息

#### 2. 多设备测试
```bash
# 设备1 上运行应用
flutter run -d device-1

# 设备2 上运行应用
flutter run -d device-2

# 两个设备上互相发送消息
```

#### 3. 功能测试清单
- [ ] 文本消息实时显示
- [ ] 图像上传和接收
- [ ] 消息历史加载
- [ ] 连接断开后自动重连
- [ ] 自发消息过滤 (不重复显示)

## 常见部署问题

### 问题 1: 后端启动失败

**症状：** `Error: Cannot find module 'ws'`

**解决方案：**
```bash
# 重新安装依赖
cd backend
rm -rf node_modules package-lock.json
npm install
node server.js
```

### 问题 2: 端口已被占用

**症状：** `Error: listen EADDRINUSE: address already in use :::3000`

**解决方案：**
```bash
# 查找占用进程
netstat -ano | findstr :3000  # Windows
lsof -i :3000                 # Linux/Mac

# 杀死进程
taskkill /PID <PID> /F        # Windows
kill -9 <PID>                 # Linux/Mac

# 或使用不同的端口
# 修改 server.js 中的 PORT 变量
```

### 问题 3: 前端无法连接到后端

**症状：** 应用显示红色离线状态

**调试步骤：**
1. 验证 IP 地址是否正确
   ```bash
   ping <server-ip>
   ```

2. 验证端口是否可访问
   ```bash
   telnet <server-ip> 3000
   ```

3. 查看应用日志
   ```bash
   flutter logs -f | grep "\[ChatClient\]"
   ```

4. 检查防火墙
   ```bash
   # Windows
   netsh advfirewall firewall add rule name="Allow P2P Chat" dir=in action=allow protocol=tcp localport=3000
   ```

### 问题 4: 消息未到达对方

**症状：** 发送消息成功但对方未收到

**调试步骤：**
1. 检查房间 ID 是否匹配
2. 查看后端日志中的广播记录
3. 检查 onMessage 回调是否被触发
   ```bash
   flutter logs -f | grep "\[P2PChat\]\[onMessage\]"
   ```

### 问题 5: 数据库错误

**症状：** `Error: SQLITE_READONLY`

**解决方案：**
```bash
# 检查文件权限
ls -l backend/messages.db

# 修复权限
chmod 666 backend/messages.db

# 或重新创建数据库
rm backend/messages.db
node server.js  # 重新运行将自动创建新数据库
```

## 性能优化

### 后端优化
```javascript
// 增加并发处理能力
const cluster = require('cluster');
const numCPUs = require('os').cpus().length;

// 增加消息缓冲区大小
server.maxConnections = 10000;
```

### 前端优化
```dart
// 调整重连参数
static const int RECONNECT_DELAY_MS = 1000;     // 降低延迟
static const int MAX_RECONNECT_ATTEMPTS = 10;   // 增加重试次数

// 优化图像压缩
await _client!.sendImage(imageBytes, quality: 50);  // 降低质量
```

### 网络优化
- 使用有线连接而不是 WiFi 来获得更稳定的连接
- 确保路由器放置在中心位置
- 避免 2.4GHz WiFi 的干扰（使用 5GHz）

## 安全加固

### LAN 环境下
- ✅ 使用 `ws://` (纯文本，但网络受信任)
- ✅ 在防火墙后面运行
- ✅ 限制只能内网 IP 访问

### 远程部署
- 🔐 配置 `wss://` (加密连接)
- 🔐 部署 SSL/TLS 证书
- 🔐 实施认证机制
- 🔐 启用 HTTPS for REST API
- 🔐 添加速率限制 (rate limiting)

### 示例：加密配置
```dart
// 前端：使用 wss://
static const String wssUrl = 'wss://your-domain.com:3000';

// 后端：配置 HTTPS
const https = require('https');
const fs = require('fs');

const server = https.createServer({
  cert: fs.readFileSync('path/to/cert.pem'),
  key: fs.readFileSync('path/to/key.pem')
});
```

## 监控和维护

### 日志监控
```bash
# 后端日志监控
tail -f server.log | grep "\[broadcast\]"

# 前端日志监控
flutter logs -f | grep "\[ChatClient\]"
```

### 数据库维护
```bash
# 备份数据库
cp backend/messages.db backend/messages.db.backup

# 数据库统计
sqlite3 backend/messages.db "SELECT COUNT(*) FROM messages;"

# 清理旧消息 (可选)
sqlite3 backend/messages.db "DELETE FROM messages WHERE ts < datetime('now', '-30 days');"
```

### 性能监控
```bash
# 监控内存使用
# Linux/Mac
top -p $(pgrep -f "node server.js")

# 网络连接数
netstat -an | grep :3000 | wc -l
```

## 故障恢复

### 自动重启脚本 (systemd)
```ini
# /etc/systemd/system/p2p-chat.service
[Unit]
Description=P2P Chat Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/p2p-chat/backend
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**启用服务：**
```bash
sudo systemctl enable p2p-chat
sudo systemctl start p2p-chat
sudo systemctl status p2p-chat
```

### 自动重启脚本 (Windows)
```batch
REM 任务计划器中创建计划任务
REM 定期检查并重启服务
tasklist | findstr /I "node.exe"
if errorlevel 1 (
    cd \path\to\backend
    start node server.js
)
```

## 备份和还原

### 备份
```bash
# 完整备份
tar -czf p2p-chat-backup-$(date +%Y%m%d).tar.gz backend/
```

### 还原
```bash
# 恢复备份
tar -xzf p2p-chat-backup-20240101.tar.gz
```

## 升级指南

### 更新 Flutter
```bash
flutter upgrade
flutter pub upgrade
```

### 更新 Node.js 依赖
```bash
cd backend
npm update
npm audit fix
```

### 安全补丁
```bash
# 检查漏洞
npm audit

# 修复漏洞
npm audit fix
```

## 性能基准

| 测试项 | 结果 | 说明 |
|--------|------|------|
| 消息延迟 | <100ms | LAN 环境 |
| 图像发送 | ~5MB/s | 依赖网络带宽 |
| 最大并发 | 1000+ | 取决于服务器 |
| CPU 使用率 | <5% | 空闲时 |
| 内存占用 | ~50MB | 运行时 |

## 支持和故障排除

### 获取帮助
1. 查看 `LAN_CHAT_GUIDE.md` 获取详细说明
2. 查看 `QUICK_START.md` 获取快速开始
3. 运行 `diagnose.sh` (Linux/Mac) 或 `diagnose.bat` (Windows)

### 常用命令
```bash
# 诊断网络
./diagnose.sh          # Linux/Mac
diagnose.bat          # Windows

# 查看日志
flutter logs -f
tail -f backend/server.log

# 测试连接
curl http://localhost:3000/api/health
```

---

**最后更新**: 2024-01-15  
**版本**: 1.0.0  
**维护者**: Development Team
