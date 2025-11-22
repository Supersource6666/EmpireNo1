// 这是改进后的聊天室页面核心改动
// 可以参考这些改动来更新你的 chat_room_page.dart

// ========== 导入新的服务 ==========
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'p2p_chat_page.dart';
import '../config.dart';
import '../services/network_service.dart';
import '../services/websocket_manager.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  // ========== 网络和连接管理 ==========
  late NetworkService _networkService;
  late WebSocketManager _wsManager;
  bool _isNetworkConnected = true;
  bool _isWebSocketConnected = false;

  // ========== UI 状态 ==========
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();

  String _username = "访客";
  String _userId = "";
  bool _isLoggedIn = false;
  String _password = "";

  List<Map<String, dynamic>> users = [];
  String _searchNickname = "";
  List<Map<String, dynamic>> _searchResults = [];
  String _groupCode = "";
  List<Map<String, dynamic>> _groupMembers = [];
  List<Map<String, dynamic>> _friendRequests = [];

  String get _apiBaseUrl {
    return 'http://${AppConfig.wsHost}:${AppConfig.wsPort}';
  }

  String getRoomId(String myId, String peerId) {
    return myId.compareTo(peerId) < 0 ? '${myId}_$peerId' : '${peerId}_$myId';
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  // ========== 初始化网络和 WebSocket 服务 ==========
  Future<void> _initializeServices() async {
    // 初始化网络服务
    _networkService = NetworkService();
    await _networkService.init();
    _networkService.addListener(_onNetworkStatusChanged);

    // 初始化 WebSocket 管理器
    _wsManager = WebSocketManager();
    _wsManager.addMessageListener(_handleWsMessage);
    _wsManager.addConnectionListener(_onWebSocketStatusChanged);

    _isNetworkConnected = _networkService.isConnected;
    if (mounted) {
      setState(() {});
    }

    if (_isLoggedIn && _isNetworkConnected) {
      _connectWebSocket();
    }
  }

  // ========== 网络状态变化回调 ==========
  void _onNetworkStatusChanged(bool isConnected) {
    print('[ChatRoom] 网络状态: ${isConnected ? '已连接' : '已断开'} (${_networkService.networkType})');

    if (!mounted) return;

    setState(() {
      _isNetworkConnected = isConnected;
    });

    if (isConnected && _isLoggedIn && !_isWebSocketConnected) {
      // 网络恢复，重新连接 WebSocket
      _connectWebSocket();
    } else if (!isConnected && _isWebSocketConnected) {
      // 网络断开，断开 WebSocket
      print('[ChatRoom] 网络已断开，断开 WebSocket 连接');
      _wsManager.disconnect();
    }
  }

  // ========== WebSocket 状态变化回调 ==========
  void _onWebSocketStatusChanged(bool isConnected) {
    print('[ChatRoom] WebSocket 状态: ${isConnected ? '已连接' : '已断开'}');

    if (!mounted) return;

    setState(() {
      _isWebSocketConnected = isConnected;
    });

    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已连接到聊天服务'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // ========== WebSocket 消息处理 ==========
  void _handleWsMessage(dynamic data) {
    try {
      final msg = data as Map<String, dynamic>;

      if (msg['type'] == 'friend_request' && mounted) {
        _fetchFriendRequests();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('收到好友申请'),
            content: Text('来自: ${msg['from']}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      } else if (msg['type'] == 'friend_update' && mounted) {
        _fetchFriends();
      } else if (msg['type'] == 'text' && mounted) {
        setState(() {
          messages.add(msg);
        });
      }
    } catch (e) {
      print('[ChatRoom] 消息处理错误: $e');
    }
  }

  // ========== WebSocket 连接 ==========
  Future<void> _connectWebSocket() async {
    if (!_isLoggedIn || !_isNetworkConnected) {
      print('[ChatRoom] 条件不足，无法连接 WebSocket (登录: $_isLoggedIn, 网络: $_isNetworkConnected)');
      return;
    }

    print('[ChatRoom] 正在连接 WebSocket...');

    final wsUrl = 'ws://${AppConfig.wsHost}:${AppConfig.wsPort}';

    final success = await _wsManager.connect(
      wsUrl: wsUrl,
      userId: _userId,
      roomId: _userId,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('连接失败，请检查网络'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ========== 发送聊天消息 ==========
  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    if (!_isWebSocketConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('未连接到聊天服务'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _wsManager.send({
      'type': 'message',
      'from': _userId,
      'body': _controller.text,
      'to': _userId,
      'room': _userId,
    });

    _controller.clear();
  }

  // ========== 登录处理 (已有代码，需要触发连接) ==========
  Future<void> _handleLogin(String username, String password) async {
    final url = Uri.parse('$_apiBaseUrl/api/login');
    try {
      final response = await http.post(url,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({"username": username, "password": password}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('登录超时'),
      );

      if (response.statusCode == 200) {
        final respBody = jsonDecode(response.body);
        if (respBody['success'] == true && respBody['user'] != null) {
          setState(() {
            _username = username;
            _password = password;
            _isLoggedIn = true;
            _userId = respBody['user']['id'];
          });

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('登录成功'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }

          // 登录成功后连接 WebSocket
          await _connectWebSocket();
          _fetchFriends();
          _fetchFriendRequests();
        } else {
          _showError('登录失败: ${respBody['error'] ?? '未知错误'}');
        }
      } else {
        _showError('登录失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _showError('登录超时，请检查网络连接');
    } catch (e) {
      _showError('登录异常: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ========== 获取好友列表 ==========
  Future<void> _fetchFriends() async {
    if (!_isLoggedIn || !_isNetworkConnected) return;

    try {
      final url = Uri.parse('$_apiBaseUrl/api/friends?userId=$_userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List friends = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            users = List<Map<String, dynamic>>.from(friends);
          });
        }
      }
    } catch (e) {
      print('[ChatRoom] 获取好友列表失败: $e');
    }
  }

  // ========== 获取好友申请 ==========
  Future<void> _fetchFriendRequests() async {
    if (!_isLoggedIn || !_isNetworkConnected) return;

    try {
      final url = Uri.parse('$_apiBaseUrl/api/friend_requests?userId=$_userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List requests = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _friendRequests = List<Map<String, dynamic>>.from(requests);
          });
        }
      }
    } catch (e) {
      print('[ChatRoom] 获取好友申请失败: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoggedIn && _isNetworkConnected) {
      _fetchFriends();
      _fetchFriendRequests();
    }
  }

  @override
  void dispose() {
    _wsManager.dispose();
    _networkService.removeListener(_onNetworkStatusChanged);
    _networkService.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ========== UI 构建 ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天室'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Row(
                children: [
                  // 网络状态指示
                  Icon(
                    _isNetworkConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isNetworkConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  // WebSocket 状态指示
                  Icon(
                    _isWebSocketConnected ? Icons.check_circle : Icons.cancel,
                    color: _isWebSocketConnected ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLoggedIn ? '已登录: $_username' : '未登录',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildChatUI(),
    );
  }

  Widget _buildChatUI() {
    if (!_isLoggedIn) {
      return _buildLoginUI();
    }

    return Column(
      children: [
        if (!_isNetworkConnected)
          Container(
            color: Colors.red,
            padding: const EdgeInsets.all(8.0),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '网络已断开，部分功能不可用',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        if (!_isWebSocketConnected && _isNetworkConnected)
          Container(
            color: Colors.orange,
            padding: const EdgeInsets.all(8.0),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '正在连接到聊天服务...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            reverse: true,
            children: messages.reversed
                .map((msg) => ListTile(
                      title: Text(msg['from'] ?? '未知用户'),
                      subtitle: Text(msg['body'] ?? ''),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: _isWebSocketConnected && _isNetworkConnected,
                  decoration: InputDecoration(
                    hintText: _isNetworkConnected ? '输入消息...' : '网络已断开',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _isWebSocketConnected ? _sendMessage : null,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginUI() {
    // 保留原有的登录 UI 代码
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('请先登录'),
          ElevatedButton(
            onPressed: () {
              // 打开登录对话框
            },
            child: const Text('登录'),
          ),
        ],
      ),
    );
  }
}
