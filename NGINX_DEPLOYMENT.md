# Nginx 部署 P2P 聊天系统 - 完整指南

## 目录
1. [Nginx 部署架构](#部署架构)
2. [安装和配置](#安装和配置)
3. [Windows 部署](#windows-部署)
4. [Linux 部署](#linux-部署)
5. [常见问题](#常见问题)

---

## 部署架构

### 传统架构（直连）
```
设备A                          设备B
(192.168.1.100)               (192.168.1.101)
    ↓                              ↓
Flutter App ←→ WebSocket ←→ Flutter App
              ← 直连 3000 →
```

**问题**:
- 需要记住后端 IP 和端口
- 防火墙可能阻止
- 不够灵活

### Nginx 反向代理架构
```
设备A                     Nginx 服务器                  设备B
(192.168.1.100)         (192.168.1.102)              (192.168.1.101)
    ↓                          ↓                           ↓
Flutter App ←→ HTTP/WS ← Nginx Proxy → WebSocket ← Flutter App
              ← 转发到 80 →     ↓         ← 3000 →
                          后端服务
                          (Node.js)
```

**优点**:
- ✅ 统一的入口点（单一 IP:端口）
- ✅ 支持 HTTPS/WSS（安全）
- ✅ 负载均衡
- ✅ 易于配置和维护
- ✅ 可以运行多个后端实例

---

## 安装和配置

### 1. 安装 Nginx

#### Windows 安装
```bash
# 方式1: 使用 Chocolatey
choco install nginx

# 方式2: 手动下载
# 下载: http://nginx.org/en/download.html
# 解压到: C:\nginx

# 启动
cd C:\nginx
start nginx

# 验证
curl http://localhost:80
```

#### Linux 安装（Ubuntu/Debian）
```bash
sudo apt-get update
sudo apt-get install nginx

# 启动
sudo systemctl start nginx
sudo systemctl enable nginx

# 验证
curl http://localhost:80
```

#### Linux 安装（CentOS/RHEL）
```bash
sudo yum install nginx

# 启动
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### macOS 安装
```bash
brew install nginx

# 启动
brew services start nginx

# 验证
curl http://localhost:80
```

---

## Windows 部署

### 步骤 1: 创建 Nginx 配置文件

创建文件: `C:\nginx\conf\nginx.conf`

```nginx
# P2P 聊天系统 Nginx 配置 (Windows)

user nobody;
worker_processes auto;
error_log logs/error.log warn;
pid logs/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log logs/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;

    # ========== 配置上游服务器 ==========
    upstream backend {
        server 127.0.0.1:3000;
        # 可以添加多个后端实例进行负载均衡
        # server 127.0.0.1:3001;
        # server 127.0.0.1:3002;
        keepalive 32;
    }

    # ========== HTTP 服务器配置 ==========
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        
        server_name _;
        
        # 日志
        access_log logs/p2p_chat_access.log main;
        error_log logs/p2p_chat_error.log warn;

        # ===== REST API 转发 =====
        location /api/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # 超时设置
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # ===== WebSocket 转发 =====
        location /ws {
            proxy_pass http://backend;
            
            # WebSocket 特定配置
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket 超时设置（长连接）
            proxy_read_timeout 86400;
            proxy_send_timeout 86400;
            
            # 禁用缓冲以支持流式数据
            proxy_buffering off;
        }

        # ===== 直接代理根路径（自动路由）=====
        location / {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # 健康检查端点
        location /health {
            access_log off;
            return 200 '{"status":"ok","server":"nginx"}';
            add_header Content-Type application/json;
        }

        # 错误页面
        error_page 404 /404.json;
        location = /404.json {
            internal;
            default_type application/json;
            return 404 '{"error":"Not Found"}';
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root html;
        }
    }
}
```

### 步骤 2: 验证 Nginx 配置

```bash
cd C:\nginx
.\nginx.exe -t
```

预期输出:
```
nginx: the configuration file C:\nginx\conf\nginx.conf syntax is ok
nginx: configuration file C:\nginx\conf\nginx.conf test is successful
```

### 步骤 3: 启动 Nginx

```bash
cd C:\nginx

# 启动
.\nginx.exe

# 停止
.\nginx.exe -s stop

# 重新加载配置
.\nginx.exe -s reload

# 优雅关闭
.\nginx.exe -s quit
```

### 步骤 4: 验证部署

```bash
# 1. 检查 Nginx 运行状态
netstat -ano | findstr :80

# 2. 测试 API 端点
curl http://localhost/api/health

# 3. 测试 WebSocket（需要后端运行）
# 使用 wscat 工具
npm install -g wscat
wscat -c ws://localhost/ws
```

### 步骤 5: 更新 Flutter 配置

编辑 `lib/config.dart`:

```dart
class AppConfig {
  // 通过 Nginx 连接（推荐）
  static const String wsHost = '192.168.1.102';  // Nginx 服务器IP
  static const int wsPort = 80;                  // HTTP/Nginx 端口
  
  // 直接使用 WebSocket 路径
  static String get wsUrl => 'ws://$wsHost:$wsPort/ws';
  static String get wssUrl => 'wss://$wsHost:$wsPort/ws';
  
  // REST API 路径
  static String get apiUrl => 'http://$wsHost:$wsPort/api';
}
```

### 步骤 6: 配置为 Windows 服务（可选）

```bash
# 方式1: 使用 WinSW
# 下载 WinSW: https://github.com/winsw/winsw/releases

# 创建 nginx-service.xml
<?xml version="1.0" encoding="UTF-8"?>
<service>
  <id>nginx</id>
  <name>Nginx Web Server</name>
  <description>Nginx web server for P2P chat</description>
  <executable>C:\nginx\nginx.exe</executable>
  <stopexecutable>C:\nginx\nginx.exe</stopexecutable>
  <stoparguments>-s stop</stoparguments>
</service>

# 安装服务
WinSW.exe install nginx-service.xml

# 启动服务
net start nginx

# 停止服务
net stop nginx
```

---

## Linux 部署

### 步骤 1: 创建 Nginx 配置

创建文件: `/etc/nginx/sites-available/p2p-chat`

```bash
sudo nano /etc/nginx/sites-available/p2p-chat
```

内容（与 Windows 类似，但路径不同）:

```nginx
# P2P 聊天系统 Nginx 配置 (Linux)

upstream backend {
    server 127.0.0.1:3000;
    keepalive 32;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    # 日志
    access_log /var/log/nginx/p2p_chat_access.log;
    error_log /var/log/nginx/p2p_chat_error.log warn;

    # 上传文件限制
    client_max_body_size 20M;

    # ===== REST API 转发 =====
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # ===== WebSocket 转发 =====
    location /ws {
        proxy_pass http://backend;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        proxy_buffering off;
    }

    # ===== 根路径 =====
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 健康检查
    location /health {
        access_log off;
        return 200 '{"status":"ok"}';
        add_header Content-Type application/json;
    }
}
```

### 步骤 2: 启用配置

```bash
# 启用配置
sudo ln -s /etc/nginx/sites-available/p2p-chat /etc/nginx/sites-enabled/p2p-chat

# 移除默认配置（如需）
sudo rm /etc/nginx/sites-enabled/default

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

### 步骤 3: 配置防火墙

```bash
# Ubuntu/Debian
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 步骤 4: 配置 HTTPS（可选但推荐）

#### 方式1: 使用 Let's Encrypt

```bash
# 安装 Certbot
sudo apt-get install certbot python3-certbot-nginx

# 获取证书
sudo certbot certonly --nginx -d your-domain.com

# 更新 Nginx 配置
sudo nano /etc/nginx/sites-available/p2p-chat
```

添加以下内容:

```nginx
# 重定向 HTTP 到 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name _;
    return 301 https://$host$request_uri;
}

# HTTPS 服务器
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # ... 其他配置与 HTTP 相同
}
```

---

## 完整部署流程

### Windows 完整部署步骤

```powershell
# 1. 安装 Nginx
choco install nginx

# 2. 复制配置文件到 Nginx 文件夹
# 将提供的 nginx.conf 复制到 C:\nginx\conf\

# 3. 验证配置
cd C:\nginx
.\nginx.exe -t

# 4. 启动 Nginx
.\nginx.exe

# 5. 启动后端服务
cd backend
npm install
node server.js

# 6. 更新 Flutter 配置
# 编辑 lib/config.dart
# 修改 wsHost = '192.168.1.102'
# 修改 wsUrl 使用 /ws 路径

# 7. 运行 Flutter 应用
flutter run

# 8. 验证部署
curl http://192.168.1.102/api/health
curl http://192.168.1.102/health
```

### Linux 完整部署步骤

```bash
# 1. 安装 Nginx
sudo apt-get update
sudo apt-get install nginx

# 2. 创建配置文件
sudo nano /etc/nginx/sites-available/p2p-chat
# 粘贴上面的 nginx.conf 内容

# 3. 启用配置
sudo ln -s /etc/nginx/sites-available/p2p-chat /etc/nginx/sites-enabled/

# 4. 验证配置
sudo nginx -t

# 5. 启动 Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# 6. 启动后端服务
cd backend
npm install
node server.js &

# 7. 验证部署
curl http://localhost/api/health
curl http://localhost/health

# 8. 查看日志
sudo tail -f /var/log/nginx/p2p_chat_access.log
sudo tail -f /var/log/nginx/p2p_chat_error.log
```

---

## 高级配置

### 1. 负载均衡

修改 `upstream backend` 部分：

```nginx
upstream backend {
    # 轮询
    server 127.0.0.1:3000 weight=1;
    server 127.0.0.1:3001 weight=1;
    server 127.0.0.1:3002 weight=1;
    
    # 或使用 IP hash (保证同一客户端总是连接同一服务器)
    # ip_hash;
    
    # 或使用最少连接
    # least_conn;
    
    keepalive 32;
}
```

### 2. 缓存配置

```nginx
# 添加到 http 块
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;

# 在 location 块中
location /api/ {
    proxy_cache my_cache;
    proxy_cache_valid 200 10m;
    proxy_cache_bypass $http_cache_control;
}
```

### 3. 速率限制

```nginx
# 限制 IP 连接速率
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

location /api/ {
    limit_req zone=api_limit burst=20 nodelay;
    proxy_pass http://backend;
}
```

### 4. Gzip 压缩

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript 
            application/json application/javascript 
            application/xml+rss application/rss+xml;
```

---

## 监控和维护

### Windows 监控

```powershell
# 查看 Nginx 进程
Get-Process nginx

# 查看 Nginx 日志
Get-Content "C:\nginx\logs\error.log" -Tail 20

# 查看访问日志
Get-Content "C:\nginx\logs\access.log" -Tail 20

# 检查 Nginx 配置
cd C:\nginx
.\nginx.exe -T
```

### Linux 监控

```bash
# 查看 Nginx 进程
ps aux | grep nginx

# 查看实时日志
tail -f /var/log/nginx/p2p_chat_access.log

# 查看错误日志
tail -f /var/log/nginx/p2p_chat_error.log

# 查看 Nginx 配置
sudo nginx -T

# 查看连接数
netstat -an | grep ESTABLISHED | wc -l

# 查看内存占用
ps aux | grep nginx | grep -v grep | awk '{print $6}'
```

---

## 常见问题

### Q1: 连接被拒绝 (Connection Refused)

**症状**: `curl: (7) Failed to connect to 127.0.0.1 port 80`

**解决**:
```bash
# 1. 检查 Nginx 是否运行
netstat -ano | findstr :80  # Windows
sudo netstat -an | grep :80  # Linux

# 2. 检查配置是否正确
nginx -t

# 3. 重启 Nginx
cd C:\nginx && .\nginx.exe -s reload  # Windows
sudo systemctl restart nginx           # Linux

# 4. 检查防火墙
netsh advfirewall firewall add rule name="Allow HTTP" dir=in action=allow protocol=tcp localport=80
```

### Q2: WebSocket 连接失败

**症状**: WebSocket 连接超时或关闭

**解决**:
```nginx
# 确保 WebSocket 头设置正确
location /ws {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400;  # 增加超时
    proxy_buffering off;        # 禁用缓冲
}
```

### Q3: 大文件上传失败

**症状**: `413 Request Entity Too Large`

**解决**:
```nginx
# 增加客户端请求体大小限制
client_max_body_size 20M;  # 根据需要调整
```

### Q4: HTTPS 连接失败

**症状**: `ssl_error_rx_record_too_long`

**解决**:
```nginx
# 确保 SSL 端口配置正确
server {
    listen 443 ssl http2;  # 必须指定 ssl
    # ... SSL 配置
}
```

### Q5: 后端连接不上

**症状**: `502 Bad Gateway`

**解决**:
```bash
# 1. 检查后端是否运行
netstat -ano | findstr :3000

# 2. 检查后端地址配置
# nginx.conf 中 upstream backend 地址是否正确

# 3. 查看错误日志
tail -f /var/log/nginx/p2p_chat_error.log

# 4. 测试后端连接
curl http://localhost:3000/api/health
```

---

## 诊断脚本

创建 `diagnose_nginx.sh` (Linux) 或 `diagnose_nginx.bat` (Windows):

### Linux 版本

```bash
#!/bin/bash
echo "Nginx 诊断工具"
echo "=============="
echo ""

echo "1. 检查 Nginx 进程"
ps aux | grep nginx | grep -v grep
echo ""

echo "2. 检查端口 80"
sudo netstat -an | grep :80
echo ""

echo "3. 测试 HTTP 连接"
curl -I http://localhost/health
echo ""

echo "4. 检查 Nginx 配置"
sudo nginx -t
echo ""

echo "5. 查看最近的错误"
sudo tail -5 /var/log/nginx/p2p_chat_error.log
echo ""

echo "6. 查看最近的访问"
sudo tail -5 /var/log/nginx/p2p_chat_access.log
```

### Windows 版本

```batch
@echo off
echo Nginx 诊断工具
echo ==============
echo.

echo 1. 检查 Nginx 进程
tasklist | findstr nginx
echo.

echo 2. 检查端口 80
netstat -ano | findstr :80
echo.

echo 3. 测试 HTTP 连接
curl -I http://localhost/health
echo.

echo 4. 检查配置
cd C:\nginx
nginx.exe -t
echo.

echo 5. 查看最近错误
type logs\error.log
echo.

pause
```

---

## 总结

| 步骤 | Windows | Linux |
|------|---------|-------|
| 安装 | choco install nginx | apt-get install nginx |
| 配置 | C:\nginx\conf\nginx.conf | /etc/nginx/sites-available/p2p-chat |
| 验证 | nginx -t | sudo nginx -t |
| 启动 | nginx | sudo systemctl start nginx |
| 重启 | nginx -s reload | sudo systemctl restart nginx |
| 日志 | logs/access.log | /var/log/nginx/access.log |

---

**最后更新**: 2024-01-15  
**版本**: 1.0  
**状态**: ✅ 生产就绪
