// ...existing code...
class AppConfig {
  // ========== 配置说明 ==========
  // 
  // 方案1: 直连后端 (传统方式)
  //   wsHost = '192.168.1.102'
  //   wsPort = 3000
  //   wsUrl = 'ws://192.168.1.102:3000'
  //
  // 方案2: 通过 Nginx 反向代理 (推荐)
  //   wsHost = '192.168.1.102'
  //   wsPort = 80 (或 443 for HTTPS)
  //   wsUrl = 'ws://192.168.1.102/ws'
  //   优点: 统一入口、更安全、支持负载均衡
  //
  // 选择方案: 改变下面的 DEPLOYMENT_MODE 常量
  
  // 部署模式: 'direct' 或 'nginx'
  static const String DEPLOYMENT_MODE = 'direct';  // ← 改为 'direct' 使用直连
  
  // 服务器地址（根据你的实际环境修改）
  static const String wsHost = '192.168.1.102';
  
  // ========== 根据部署模式自动选择端口 ==========
  static const int wsPort = DEPLOYMENT_MODE == 'nginx' ? 80 : 3000;
  
  // ========== WebSocket URL 配置 ==========
  // Nginx 模式: 通过 /ws 路径转发
  // 直连模式: 直接连接后端端口
  static String get wsUrl {
    if (DEPLOYMENT_MODE == 'nginx') {
      // Nginx 反向代理模式
      return 'ws://$wsHost:$wsPort/ws';
    } else {
      // 直连后端模式
      return 'ws://$wsHost:$wsPort';
    }
  }
  
  // ========== HTTPS/WSS 配置 ==========
  static String get wssUrl {
    if (DEPLOYMENT_MODE == 'nginx') {
      return 'wss://$wsHost:443/ws';
    } else {
      return 'wss://$wsHost:3000';
    }
  }
  
  // ========== REST API 配置 ==========
  static String get apiUrl {
    if (DEPLOYMENT_MODE == 'nginx') {
      return 'http://$wsHost:$wsPort/api';
    } else {
      return 'http://$wsHost:3000/api';
    }
  }
}
// ...existing code...