# ✅ Nginx 部署完整清单

## 📋 部署前准备

### 环境检查
- [ ] 已安装 Node.js 14+
- [ ] 已安装 Flutter 3.0+
- [ ] 已安装 Git
- [ ] 局域网内有多台设备可测试

### 获取文件
- [ ] 下载 `deploy_nginx.sh` (Linux) 或 `deploy_nginx.bat` (Windows)
- [ ] 下载 `nginx.conf.example` 配置示例
- [ ] 确认 Flutter 项目已准备好

---

## 🚀 Windows 部署流程

### 第1步: 运行自动部署脚本

```
步骤:
□ 1. 以管理员身份运行 deploy_nginx.bat
□ 2. 脚本会自动:
   □ 检查/安装 Nginx
   □ 配置 nginx.conf
   □ 启动 Nginx 服务
   □ 验证防火墙规则
```

### 第2步: 启动后端服务

```
步骤:
□ 1. 打开 PowerShell
□ 2. 进入项目目录
   cd backend
□ 3. 安装依赖
   npm install
□ 4. 启动服务
   node server.js
```

### 第3步: 验证配置

```
步骤:
□ 1. 验证 Nginx 运行
   netstat -ano | findstr :80
□ 2. 测试 API 端点
   curl http://localhost/health
□ 3. 测试 WebSocket
   npm install -g wscat
   wscat -c ws://localhost/ws
```

### 第4步: 更新 Flutter 配置

```
步骤:
□ 1. 打开 lib/config.dart
□ 2. 确认配置:
   DEPLOYMENT_MODE = 'nginx'  ✓ (默认已配置)
   wsHost = '192.168.1.102'
□ 3. 根据实际 IP 修改 wsHost
```

### 第5步: 运行 Flutter 应用

```
步骤:
□ 1. 打开新的 PowerShell 窗口
□ 2. 运行应用
   flutter run
□ 3. 验证连接
   查看 AppBar 中的连接状态指示器 (应为绿色)
```

### 第6步: 跨设备测试

```
步骤:
□ 1. 在第二台设备上:
   flutter run -d <device-id>
□ 2. 在两个设备间发送消息
□ 3. 验证消息实时显示
□ 4. 测试图像上传
```

---

## 🐧 Linux (Ubuntu/Debian) 部署流程

### 第1步: 准备权限

```bash
□ chmod +x deploy_nginx.sh
```

### 第2步: 运行自动部署脚本

```bash
□ sudo ./deploy_nginx.sh

脚本会自动:
□ 更新系统包
□ 安装 Nginx
□ 配置 nginx.conf
□ 启动 Nginx 服务
□ 配置防火墙规则 (UFW)
```

### 第3步: 启动后端服务

```bash
□ cd backend
□ npm install
□ node server.js &
```

### 第4步: 验证配置

```bash
□ sudo systemctl status nginx
□ curl http://localhost/health
□ wscat -c ws://localhost/ws
```

### 第5步: 更新 Flutter 配置

```
(同 Windows 第4步)
```

### 第6步: 运行 Flutter 应用

```bash
□ flutter run
或在特定设备上:
□ flutter run -d <device-id>
```

### 第7步: 跨设备测试

```
(同 Windows 第6步)
```

---

## 📊 部署验证检查表

### Nginx 服务检查

```
□ Nginx 进程运行
  Windows: tasklist | findstr nginx
  Linux: ps aux | grep nginx

□ 端口 80 监听
  Windows: netstat -ano | findstr :80
  Linux: sudo netstat -an | grep :80

□ 配置文件有效
  nginx -t (应显示 "successful")

□ 可访问健康检查端点
  curl http://localhost/health (返回 OK)
```

### 后端服务检查

```
□ Node.js 进程运行
  netstat -ano | findstr :3000
  ps aux | grep node

□ REST API 可访问
  curl http://localhost:3000/api/health

□ 无明显错误日志
  Windows: type C:\nginx\logs\error.log
  Linux: tail /var/log/nginx/error.log
```

### Flutter 应用检查

```
□ 应用成功启动
□ AppBar 显示连接状态 (应为绿色)
□ 可输入和发送消息
□ 消息本地显示成功
□ 日志无明显错误
  flutter logs -f | grep "\[P2PChat\]"
```

### 网络连接检查

```
□ 从本地访问成功
  curl http://localhost/health

□ 从 LAN 地址访问成功
  curl http://192.168.x.x/health

□ WebSocket 连接成功
  wscat -c ws://192.168.x.x/ws

□ 跨设备通信成功
  两个设备间能互相发送和接收消息
```

---

## 🔧 常见部署问题快速修复

### 问题1: 权限被拒绝 (Windows)

```
症状: "拒绝访问"
解决: 以管理员身份运行 deploy_nginx.bat
   右键 deploy_nginx.bat → "以管理员身份运行"
```

### 问题2: 端口已被占用

```
症状: "Address already in use :80"
解决: 
□ 停止现有 Nginx: nginx -s stop (Windows) 或 systemctl stop nginx (Linux)
□ 或检查是否已有其他 HTTP 服务
  Windows: netstat -ano | findstr :80
  Linux: sudo netstat -an | grep :80
```

### 问题3: 防火墙阻止

```
症状: 外部设备无法访问
解决:
□ Windows: 允许 Nginx 通过防火墙
  powershell -Command "New-NetFirewallRule -DisplayName 'Allow Nginx' -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow"

□ Linux: 配置 UFW 或 Firewalld
  sudo ufw allow 80/tcp
  或
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --reload
```

### 问题4: WebSocket 连接失败

```
症状: WebSocket 连接超时
解决:
□ 检查 Nginx 配置中的 WebSocket 超时设置
  应有: proxy_read_timeout 86400s;
□ 检查后端是否运行
  netstat -ano | findstr :3000
□ 重启 Nginx
  nginx -s reload (Windows)
  sudo systemctl restart nginx (Linux)
```

### 问题5: 502 Bad Gateway

```
症状: 访问返回 502 错误
解决:
□ 检查后端是否运行
□ 检查后端地址 (nginx.conf 中 upstream)
□ 查看 Nginx 错误日志
  type C:\nginx\logs\error.log
  tail -f /var/log/nginx/error.log
```

### 问题6: 无法从其他设备访问

```
症状: 192.168.x.x 无法访问
解决:
□ 确认使用正确的 IP 地址
  ipconfig (Windows)
  hostname -I (Linux)
□ 测试网络连通性
  ping 192.168.x.x
□ 检查防火墙
□ 检查网络隔离 (是否在同一网络)
```

---

## 📈 部署验证步骤

### 步骤1: 本地验证 (单机)

```
□ 启动 Nginx
□ 启动后端服务
□ 运行应用
□ 查看 AppBar (应显示绿色连接状态)
□ 发送测试消息
□ 验证消息显示
```

### 步骤2: 同设备多客户端验证

```
□ 在同一设备上运行两个 Flutter 应用实例
□ 互相发送消息
□ 验证收发成功
```

### 步骤3: 跨设备验证 (多台设备)

```
□ 在设备 A 上运行应用
□ 在设备 B 上运行应用
□ 从 A 发送消息到 B
□ 从 B 发送消息到 A
□ 验证双向通信成功
```

### 步骤4: 功能验证

```
□ 文本消息
  ✓ 发送
  ✓ 接收
  ✓ 多条消息
  ✓ 消息历史

□ 图像消息
  ✓ 发送小图像 (<1MB)
  ✓ 发送中等图像 (1-5MB)
  ✓ 接收图像
  ✓ 图像显示

□ 连接管理
  ✓ 自动连接
  ✓ 连接断开后重连
  ✓ 网络异常恢复

□ UI/UX
  ✓ 连接状态显示
  ✓ 消息实时显示
  ✓ 错误提示
  ✓ 响应式布局
```

---

## 📊 性能测试检查表

### 基准测试

```
□ 单条消息延迟
  目标: <100ms
  测试: 发送时戳 vs 接收时戳

□ 吞吐量
  目标: 100+ 消息/秒
  测试: 快速发送多条消息

□ 连接建立时间
  目标: <2秒
  测试: 启动应用到显示连接状态

□ 图像上传速度
  目标: >1MB/秒
  测试: 上传 5MB 图像测量时间
```

### 压力测试

```
□ 多个并发连接
  测试: 10个设备同时连接

□ 大消息处理
  测试: 发送 10MB+ 文件

□ 长时间运行
  测试: 应用运行 1小时+
  验证: 无内存泄漏、无连接丢失

□ 网络波动
  测试: 模拟网络不稳定
  验证: 自动重连、消息重发
```

---

## 🎯 部署成功标志

✅ **部署成功，当您看到以下情况时:**

1. ✓ Nginx 已安装并运行
   - Windows: `netstat -ano | findstr :80` 有输出
   - Linux: `ps aux | grep nginx` 有输出

2. ✓ 后端服务已启动
   - `netstat -ano | findstr :3000` 有输出
   - `curl http://localhost:3000/api/health` 返回 200

3. ✓ Nginx 代理配置正确
   - `curl http://localhost/health` 返回 OK
   - `curl http://192.168.x.x/health` 返回 OK

4. ✓ Flutter 应用连接成功
   - AppBar 显示绿色 "已连接" 状态
   - 应用 logs 无错误信息
   - 消息本地显示成功

5. ✓ 跨设备通信成功
   - 能在两个设备间互相发送消息
   - 消息实时显示 (<100ms)
   - 图像能上传和下载

6. ✓ 稳定性验证
   - 运行 30 分钟无崩溃
   - 网络异常能自动恢复
   - 日志无警告或错误

---

## 📞 获取帮助

### 首先查看

1. [NGINX_DEPLOYMENT.md](NGINX_DEPLOYMENT.md) - 详细部署指南
2. [NGINX_QUICK_REFERENCE.md](NGINX_QUICK_REFERENCE.md) - 快速参考
3. 本文件的"常见问题快速修复"部分

### 然后运行诊断

```bash
# Linux
./diagnose.sh

# Windows
diagnose.bat
```

### 最后查看日志

```bash
# Windows
type C:\nginx\logs\error.log
type C:\nginx\logs\access.log

# Linux
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/p2p_chat_access.log
```

---

## 📝 记录和文档

### 部署信息记录

在此记录您的部署信息以便日后参考:

```
部署日期: _______________
服务器 IP: _______________
所有设备 IP: _______________
Nginx 版本: _______________
Node.js 版本: _______________
Flutter 版本: _______________

备注:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## 🎉 下一步

部署完成后，您可以:

✅ 在局域网内轻松共享 P2P 聊天应用
✅ 支持多个设备同时连接
✅ 快速扩展和维护系统
✅ 准备向生产环境迁移

### 可选的后续改进

1. 🔐 配置 HTTPS (Let's Encrypt)
2. 📊 设置监控和告警
3. 🎯 性能优化
4. 🔄 自动化部署
5. 🐳 容器化 (Docker)

---

**部署完成日期**: _________________  
**已验证通过**: ☐ 是  ☐ 否  
**系统状态**: ☐ 生产就绪  ☐ 需要调整

---

**版本**: 1.0  
**最后更新**: 2024-01-15
