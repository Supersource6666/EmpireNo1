#!/bin/bash
# P2P 聊天系统 Nginx 快速部署脚本 (Linux)
# 
# 使用方法:
#   chmod +x deploy_nginx.sh
#   sudo ./deploy_nginx.sh
#
# 支持: Ubuntu, Debian, CentOS, RHEL

set -e

echo "======================================"
echo "P2P 聊天系统 Nginx 部署工具"
echo "======================================"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
   echo "❌ 需要 root 权限，请使用 sudo 运行"
   exit 1
fi

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "❌ 无法检测操作系统"
    exit 1
fi

echo "✓ 检测到操作系统: $OS $VER"
echo ""

# ========== 步骤 1: 安装 Nginx ==========
echo "步骤 1/5: 安装 Nginx..."

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt-get update
    apt-get install -y nginx
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
    yum install -y nginx
else
    echo "❌ 不支持的操作系统: $OS"
    exit 1
fi

echo "✓ Nginx 安装完成"
echo ""

# ========== 步骤 2: 创建配置文件 ==========
echo "步骤 2/5: 配置 Nginx..."

# 备份原配置
if [ -f /etc/nginx/sites-available/default ]; then
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
fi

# 创建新配置
cat > /etc/nginx/sites-available/p2p-chat << 'EOF'
# P2P 聊天系统 Nginx 配置

upstream backend {
    server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    access_log /var/log/nginx/p2p_chat_access.log;
    error_log /var/log/nginx/p2p_chat_error.log warn;
    
    client_max_body_size 20M;

    # REST API
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # WebSocket
    location /ws {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
        proxy_buffering off;
    }

    # 其他路由
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
        default_type application/json;
        return 200 '{"status":"ok"}';
    }
}
EOF

echo "✓ Nginx 配置完成"
echo ""

# ========== 步骤 3: 启用配置 ==========
echo "步骤 3/5: 启用配置..."

# Ubuntu/Debian
if [ -d /etc/nginx/sites-enabled ]; then
    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/p2p-chat /etc/nginx/sites-enabled/
fi

# 验证配置
if ! nginx -t; then
    echo "❌ Nginx 配置验证失败"
    exit 1
fi

echo "✓ 配置启用完成"
echo ""

# ========== 步骤 4: 启动 Nginx ==========
echo "步骤 4/5: 启动 Nginx..."

systemctl start nginx
systemctl enable nginx

# 等待启动
sleep 2

# 验证
if systemctl is-active --quiet nginx; then
    echo "✓ Nginx 启动成功"
else
    echo "❌ Nginx 启动失败"
    systemctl status nginx
    exit 1
fi

echo ""

# ========== 步骤 5: 配置防火墙 ==========
echo "步骤 5/5: 配置防火墙..."

if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    echo "✓ UFW 防火墙已配置"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    echo "✓ Firewalld 防火墙已配置"
else
    echo "⚠ 未检测到防火墙管理工具，请手动配置"
fi

echo ""

# ========== 显示信息 ==========
echo "======================================"
echo "✅ 部署完成！"
echo "======================================"
echo ""

# 获取本机 IP
LOCAL_IP=$(hostname -I | awk '{print $1}')

echo "📋 配置信息:"
echo "   Nginx 状态: $(systemctl is-active nginx)"
echo "   访问地址: http://$LOCAL_IP"
echo "   API 地址: http://$LOCAL_IP/api"
echo "   WebSocket: ws://$LOCAL_IP/ws"
echo ""

echo "📝 后续步骤:"
echo "   1. 启动后端服务:"
echo "      cd backend"
echo "      npm install"
echo "      node server.js"
echo ""
echo "   2. 修改 Flutter 配置 (lib/config.dart):"
echo "      static const String wsHost = '$LOCAL_IP';"
echo "      static const int wsPort = 80;"
echo "      static String get wsUrl => 'ws://\$wsHost:\$wsPort/ws';"
echo ""
echo "   3. 运行 Flutter 应用:"
echo "      flutter run"
echo ""

echo "📊 查看日志:"
echo "   tail -f /var/log/nginx/p2p_chat_access.log"
echo "   tail -f /var/log/nginx/p2p_chat_error.log"
echo ""

echo "🔧 常用命令:"
echo "   sudo systemctl status nginx"
echo "   sudo systemctl restart nginx"
echo "   sudo nginx -t"
echo "   curl http://$LOCAL_IP/health"
echo ""
