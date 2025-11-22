import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'network_service.dart';

/// WebSocket 连接管理器 - 自动重连和错误恢复
class WebSocketManager {
  late String _wsUrl;
  late String _userId;
  late String _roomId;
  
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  bool _isManuallyClosed = false;
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);

  final List<Function(dynamic)> _messageListeners = [];
  final List<Function(bool)> _connectionListeners = [];

  /// 初始化 WebSocket 连接
  Future<bool> connect({
    required String wsUrl,
    required String userId,
    required String roomId,
  }) async {
    if (_channel != null && !_isManuallyClosed) {
      return true; // 已连接
    }

    _wsUrl = wsUrl;
    _userId = userId;
    _roomId = roomId;
    _isManuallyClosed = false;

    return _attemptConnect();
  }

  Future<bool> _attemptConnect() async {
    if (_isConnecting) return false;

    _isConnecting = true;
    try {
      // 尝试连接
      _channel = IOWebSocketChannel.connect(_wsUrl,
          connectTimeout: const Duration(seconds: 10));

      // 等待连接建立
      await Future.delayed(const Duration(milliseconds: 500));

      if (_channel != null) {
        // 发送加入房间消息
        _send({
          'type': 'join',
          'from': _userId,
          'room': _roomId,
        });

        // 监听消息
        _channel!.stream.listen(
          (data) => _onMessage(data),
          onDone: _onConnectionClosed,
          onError: (error) => _onError(error),
        );

        _reconnectAttempts = 0;
        _notifyConnectionChange(true);
        _isConnecting = false;
        return true;
      }
    } catch (e) {
      print('[WebSocket] 连接失败: $e');
      _channel = null;
    }

    _isConnecting = false;
    _scheduleReconnect();
    return false;
  }

  void _onMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      for (var listener in _messageListeners) {
        listener(message);
      }
    } catch (e) {
      print('[WebSocket] 消息处理错误: $e');
    }
  }

  void _onConnectionClosed() {
    print('[WebSocket] 连接已关闭');
    _channel = null;
    _notifyConnectionChange(false);

    if (!_isManuallyClosed) {
      _scheduleReconnect();
    }
  }

  void _onError(dynamic error) {
    print('[WebSocket] 连接错误: $error');
    _channel = null;
    _notifyConnectionChange(false);

    if (!_isManuallyClosed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isManuallyClosed || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    // 指数退避: 2s, 4s, 8s, 16s...
    final delay = _baseReconnectDelay * (1 << (_reconnectAttempts - 1));

    print('[WebSocket] 将在 ${delay.inSeconds}s 后进行第 $_reconnectAttempts 次重连');

    _reconnectTimer = Timer(delay, () {
      if (!_isManuallyClosed) {
        _attemptConnect();
      }
    });
  }

  /// 发送消息
  void send(Map<String, dynamic> message) {
    _send(message);
  }

  void _send(Map<String, dynamic> message) {
    if (_channel == null) {
      print('[WebSocket] 未连接，消息未送出: $message');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      print('[WebSocket] 发送消息失败: $e');
    }
  }

  /// 添加消息监听
  void addMessageListener(Function(dynamic) callback) {
    _messageListeners.add(callback);
  }

  /// 移除消息监听
  void removeMessageListener(Function(dynamic) callback) {
    _messageListeners.remove(callback);
  }

  /// 添加连接状态监听
  void addConnectionListener(Function(bool) callback) {
    _connectionListeners.add(callback);
    // 立即发送当前状态
    callback(isConnected);
  }

  /// 移除连接状态监听
  void removeConnectionListener(Function(bool) callback) {
    _connectionListeners.remove(callback);
  }

  void _notifyConnectionChange(bool isConnected) {
    for (var listener in _connectionListeners) {
      listener(isConnected);
    }
  }

  /// 获取连接状态
  bool get isConnected => _channel != null;

  /// 断开连接
  void disconnect() {
    _isManuallyClosed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _messageListeners.clear();
    _connectionListeners.clear();
    _notifyConnectionChange(false);
  }

  /// 清理资源
  void dispose() {
    disconnect();
  }
}
