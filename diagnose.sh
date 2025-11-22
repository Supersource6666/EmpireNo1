#!/bin/bash
# P2P 聊天系统诊断脚本
# 用于快速检查和诊断常见问题

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================="
echo "P2P 聊天系统诊断工具"
echo "======================================="
echo ""

# 获取用户输入
read -p "请输入服务器 IP 地址 [默认: 192.168.1.102]: " SERVER_IP
SERVER_IP=${SERVER_IP:-192.168.1.102}
read -p "请输入服务器端口 [默认: 3000]: " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-3000}

echo ""
echo "配置信息："
echo "  服务器 IP: $SERVER_IP"
echo "  服务器端口: $SERVER_PORT"
echo ""

# 1. 检查网络连接
echo -e "${YELLOW}[1/5] 检查网络连接...${NC}"
if ping -c 1 "$SERVER_IP" &> /dev/null; then
    echo -e "${GREEN}✓ 网络连接正常${NC}"
else
    echo -e "${RED}✗ 无法连接到服务器 IP: $SERVER_IP${NC}"
    echo "  建议："
    echo "  - 检查设备是否连接到正确的网络"
    echo "  - 检查 IP 地址是否正确"
    echo "  - 检查防火墙设置"
    echo ""
fi

# 2. 检查端口是否开放
echo -e "${YELLOW}[2/5] 检查服务器端口...${NC}"
if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$SERVER_IP/$SERVER_PORT" 2>/dev/null; then
    echo -e "${GREEN}✓ 服务器端口 $SERVER_PORT 开放${NC}"
else
    echo -e "${RED}✗ 无法连接到端口 $SERVER_PORT${NC}"
    echo "  建议："
    echo "  - 检查后端服务器是否运行"
    echo "  - 在服务器上执行: node server.js"
    echo "  - 检查防火墙是否允许该端口"
    echo ""
fi

# 3. 检查 REST API
echo -e "${YELLOW}[3/5] 检查 REST API...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "http://$SERVER_IP:$SERVER_PORT/api/health" 2>/dev/null | tail -1)
if [ "$RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ REST API 响应正常${NC}"
else
    echo -e "${RED}✗ REST API 响应异常 (HTTP $RESPONSE)${NC}"
    echo "  建议："
    echo "  - 检查后端服务器日志"
    echo "  - 确保 Express 服务器已启动"
    echo ""
fi

# 4. 检查本地网络信息
echo -e "${YELLOW}[4/5] 检查本地网络信息...${NC}"
echo "本地网络接口："
if command -v ifconfig &> /dev/null; then
    ifconfig | grep -E "^[a-z]|inet " | head -20
elif command -v ip &> /dev/null; then
    ip addr show | grep -E "^[0-9]|inet " | head -20
else
    echo "无法获取网络信息"
fi
echo ""

# 5. 检查本地IP地址
echo -e "${YELLOW}[5/5] 获取本地 IP 地址...${NC}"
if command -v hostname &> /dev/null; then
    LOCAL_IP=$(hostname -I | awk '{print $1}')
else
    LOCAL_IP="无法获取"
fi
echo "本地 IP 地址: $LOCAL_IP"
echo ""

# 总结
echo "======================================="
echo "诊断总结"
echo "======================================="
echo ""
echo "如果连接失败，请按以下顺序检查："
echo ""
echo "1️⃣  确保后端服务器已启动:"
echo "    cd backend"
echo "    npm install"
echo "    node server.js"
echo ""
echo "2️⃣  确认 IP 地址正确:"
echo "    在 config.dart 中设置: wsHost = '$SERVER_IP'"
echo ""
echo "3️⃣  检查防火墙设置:"
echo "    Windows: netsh advfirewall firewall add rule name=\"Allow Port $SERVER_PORT\" dir=in action=allow protocol=tcp localport=$SERVER_PORT"
echo "    Linux/Mac: sudo ufw allow $SERVER_PORT"
echo ""
echo "4️⃣  检查网络连接:"
echo "    所有设备应该在同一 WiFi 或局域网上"
echo ""
echo "5️⃣  查看应用日志:"
echo "    flutter logs -f"
echo ""
echo "======================================="
