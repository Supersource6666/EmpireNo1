// ...existing code...
class AppConfig {
  static const String wsHost = '192.168.200.211';
  static const int wsPort = 3000;
  static String get wsUrl => 'ws://$wsHost:$wsPort';
  static String get wssUrl => 'wss://$wsHost:$wsPort';
}
// ...existing code...