# Nginx 部署快速参考

## 📋 一页纸快速指南

### Windows 快速部署

```powershell
# 1. 以管理员身份运行快速部署脚本
.\deploy_nginx.bat

# 2. 启动后端
cd backend
npm install
node server.js

# 3. 修改 Flutter 配置
# 编辑 lib/config.dart
# wsHost = '192.168.1.102'  (你的机器IP)
# wsUrl = 'ws://192.168.1.102/ws'

# 4. 运行应用
flutter run

# 5. 验证
curl http://192.168.1.102/health
```

### Linux 快速部署

```bash
# 1. 运行自动部署脚本
chmod +x deploy_nginx.sh
sudo ./deploy_nginx.sh

# 2. 启动后端
cd backend
npm install
node server.js &

# 3. 修改 Flutter 配置
# 编辑 lib/config.dart
# wsHost = '192.168.1.102'  (你的机器IP)
# wsUrl = 'ws://192.168.1.102/ws'

# 4. 运行应用
flutter run

# 5. 验证
curl http://192.168.1.102/health
```

---

## 🔧 常用命令速查表

### Windows

| 操作 | 命令 |
|------|------|
| 启动 Nginx | `cd C:\nginx && nginx.exe` |
| 停止 Nginx | `nginx.exe -s stop` |
| 重启 Nginx | `nginx.exe -s reload` |
| 验证配置 | `nginx.exe -t` |
| 查看进程 | `netstat -ano \| findstr :80` |
| 查看日志 | `type C:\nginx\logs\error.log` |
| 测试连接 | `curl http://localhost/health` |
| 允许防火墙 | `powershell -Command "New-NetFirewallRule -DisplayName 'Allow Nginx' -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow"` |

### Linux

| 操作 | 命令 |
|------|------|
| 启动 Nginx | `sudo systemctl start nginx` |
| 停止 Nginx | `sudo systemctl stop nginx` |
| 重启 Nginx | `sudo systemctl restart nginx` |
| 验证配置 | `sudo nginx -t` |
| 查看进程 | `ps aux \| grep nginx` |
| 查看日志 | `sudo tail -f /var/log/nginx/p2p_chat_access.log` |
| 测试连接 | `curl http://localhost/health` |
| 查看端口 | `sudo netstat -an \| grep :80` |

---

## 📁 文件结构对比

### 直连方案 vs Nginx 反向代理

```
直连方案 (传统):
设备 → Node.js:3000 (后端直接暴露)

Nginx 反向代理方案:
设备 → Nginx:80 → Node.js:3000 (后端隐藏在代理后)
```

---

## 🚀 部署场景

### 场景1: 局域网内单机部署

**架构**:
```
所有设备 → Nginx:80 (192.168.1.102) → Node.js:3000 (同一机器)
```

**配置**:
```nginx
upstream backend {
    server 127.0.0.1:3000;
}
```

**Flutter 配置**:
```dart
static const String wsHost = '192.168.1.102';
static const int wsPort = 80;
```

### 场景2: 负载均衡（多后端实例）

**架构**:
```
所有设备 → Nginx:80 → [Node.js:3000, Node.js:3001, Node.js:3002]
```

**配置**:
```nginx
upstream backend {
    server 127.0.0.1:3000 weight=1;
    server 127.0.0.1:3001 weight=1;
    server 127.0.0.1:3002 weight=1;
}
```

**启动后端**:
```bash
PORT=3000 node server.js &
PORT=3001 node server.js &
PORT=3002 node server.js &
```

### 场景3: 远程部署（带HTTPS）

**架构**:
```
互联网设备 → Nginx:443 (wss://) → Node.js:3000
             ↓
          SSL证书 (Let's Encrypt)
```

**配置**: 见 NGINX_DEPLOYMENT.md 的 HTTPS 章节

---

## ⚙️ 核心配置说明

### WebSocket 转发关键配置

```nginx
location /ws {
    proxy_pass http://backend;
    
    # 1. 协议升级
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    
    # 2. 长连接支持
    proxy_read_timeout 86400s;   # 24小时
    proxy_send_timeout 86400s;
    
    # 3. 禁用缓冲（实时双向通信）
    proxy_buffering off;
}
```

### API 转发关键配置

```nginx
location /api/ {
    proxy_pass http://backend;
    
    # 1. HTTP 1.1 连接复用
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    
    # 2. 代理头信息
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    
    # 3. 合理超时（短连接）
    proxy_connect_timeout 30s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;
}
```

---

## 🔍 故障排除快速导航

### 问题1: 连接被拒绝

```bash
# 诊断命令
netstat -ano | findstr :80          # Windows
sudo netstat -an | grep :80          # Linux

# 解决方案
# 1. 检查 Nginx 是否运行
# 2. 检查防火墙配置
# 3. 检查配置文件语法
nginx -t
```

### 问题2: WebSocket 连接超时

```bash
# 检查配置是否有 WebSocket 超时设置
# 应该有:
# proxy_read_timeout 86400s;
# proxy_buffering off;
```

### 问题3: 502 Bad Gateway

```bash
# 1. 检查后端是否运行
netstat -ano | findstr :3000

# 2. 手动测试后端
curl http://localhost:3000/api/health

# 3. 查看 Nginx 错误日志
tail -f /var/log/nginx/error.log    # Linux
type C:\nginx\logs\error.log         # Windows
```

### 问题4: 无法从其他设备访问

```bash
# 1. 检查防火墙
# Windows: 使用 Windows Defender 防火墙设置
# Linux: sudo ufw allow 80/tcp

# 2. 确认使用正确的 IP
ipconfig                             # Windows
hostname -I                          # Linux
ifconfig                             # macOS

# 3. 测试网络连通性
ping 192.168.1.102
curl http://192.168.1.102/health
```

---

## 📊 性能调优参数

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| worker_processes | auto | 自动匹配 CPU 核心数 |
| worker_connections | 2048 | 每个 worker 进程的连接数 |
| keepalive | 32 | 上游连接池大小 |
| client_max_body_size | 20M | 上传文件大小限制 |
| proxy_read_timeout | 86400s | WebSocket 连接超时 |
| gzip_comp_level | 6 | Gzip 压缩级别 (1-9) |

---

## 🔐 安全配置

### 最小安全配置

```nginx
# 隐藏 Nginx 版本
server_tokens off;

# 限制请求体大小
client_max_body_size 20M;

# 设置安全头
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

### 防火墙规则

```bash
# Linux UFW
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Linux Firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Windows Firewall
netsh advfirewall firewall add rule name="Allow HTTP" dir=in action=allow protocol=tcp localport=80
netsh advfirewall firewall add rule name="Allow HTTPS" dir=in action=allow protocol=tcp localport=443
```

---

## 📈 监控和日志

### 日志位置

```
Windows: C:\nginx\logs\
Linux:   /var/log/nginx/

关键文件:
- access.log    # 访问日志
- error.log     # 错误日志
```

### 查看实时日志

```bash
# Linux
tail -f /var/log/nginx/p2p_chat_access.log
tail -f /var/log/nginx/p2p_chat_error.log

# Windows PowerShell
Get-Content C:\nginx\logs\access.log -Tail 20 -Wait
```

### 性能统计

```bash
# 查看 Nginx 状态（需要在 nginx.conf 配置）
curl http://localhost/nginx_status

# 输出示例
Active connections: 10
server accepts handled requests
          1000   1000   2000
Reading: 1 Writing: 2 Waiting: 7
```

---

## 🎯 检查清单

部署前:
- [ ] Nginx 已安装
- [ ] 配置文件已正确修改
- [ ] 防火墙规则已配置
- [ ] 后端服务已启动
- [ ] 本地测试通过

部署后:
- [ ] http://localhost/health 返回 OK
- [ ] http://192.168.x.x/health 可访问
- [ ] WebSocket 连接成功
- [ ] 跨设备通信正常
- [ ] 日志无错误信息

---

## 📞 获取帮助

查看完整文档:
- [NGINX_DEPLOYMENT.md](NGINX_DEPLOYMENT.md) - 详细部署指南
- [QUICK_START.md](QUICK_START.md) - 基础快速开始
- [LAN_CHAT_GUIDE.md](LAN_CHAT_GUIDE.md) - 功能完整指南

---

**最后更新**: 2024-01-15  
**版本**: 1.0
