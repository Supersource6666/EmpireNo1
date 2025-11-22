import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// 网络连接服务 - 监听网络状态变化
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  bool _isConnected = true;
  ConnectivityResult? _lastResult;
  
  // 连接状态变化回调
  final List<Function(bool)> _listeners = [];

  NetworkService._internal();

  factory NetworkService() {
    return _instance;
  }

  Future<void> init() async {
    // 检查当前网络状态
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // 监听网络状态变化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        _updateConnectionStatus(result.first);
      },
    );
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _lastResult = result;
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    // 只在状态改变时通知
    if (wasConnected != _isConnected) {
      _notifyListeners(_isConnected);
    }
  }

  void _notifyListeners(bool isConnected) {
    for (var listener in _listeners) {
      listener(isConnected);
    }
  }

  /// 添加网络状态监听
  void addListener(Function(bool) callback) {
    _listeners.add(callback);
  }

  /// 移除网络状态监听
  void removeListener(Function(bool) callback) {
    _listeners.remove(callback);
  }

  /// 获取当前网络状态
  bool get isConnected => _isConnected;

  /// 获取网络类型
  String get networkType {
    switch (_lastResult) {
      case ConnectivityResult.mobile:
        return '移动网络';
      case ConnectivityResult.wifi:
        return '无线网络';
      case ConnectivityResult.ethernet:
        return '以太网';
      case ConnectivityResult.none:
        return '无网络';
      default:
        return '未知';
    }
  }

  /// 清理资源
  void dispose() {
    _connectivitySubscription.cancel();
    _listeners.clear();
  }
}
