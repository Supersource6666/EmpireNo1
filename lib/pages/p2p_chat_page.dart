import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatBubble({required this.text, required this.isMe, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isMe ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: isMe ? Radius.circular(12) : Radius.zero,
              bottomRight: isMe ? Radius.zero : Radius.circular(12),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}

class P2PChatPage extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String wsMode; // "lan" or "remote"
  final String myId;
  final String roomId;
  const P2PChatPage({required this.peerId, required this.peerName, required this.wsMode, required this.myId, required this.roomId, Key? key}) : super(key: key);

  @override
  State<P2PChatPage> createState() => _P2PChatPageState();
}

class _P2PChatPageState extends State<P2PChatPage> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatClient? _client;
  bool _connected = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    print('[P2PChat][initState] myId: '+widget.myId+', peerId: '+widget.peerId+', roomId: '+widget.roomId+', wsMode: '+widget.wsMode);
    _loadHistory();
    _initClient();
  }

  void _loadHistory() async {
    final url = Uri.parse('${AppConfig.apiUrl}/history?user1=${widget.myId}&user2=${widget.peerId}');
    try {
      final response = await http.get(url);
      final obj = jsonDecode(response.body);
      if (obj['success'] == true && obj['messages'] is List) {
        setState(() {
          for (var msg in obj['messages']) {
            messages.add({
              "type": "text",
              "text": msg['body'],
              "isMe": msg['from_user'] == widget.myId, // 判断是否是当前用户发送
              "from": msg['from_user'],
              "ts": msg['ts'] ?? ""
            });
          }
        });
      }
    } catch (e) {
      // 可选：错误提示
      print('Error loading history: $e');
    }
  }

  void _initClient() async {
    print('[P2PChat][_initClient] 创建ChatClient, userId: '+widget.myId+', roomId: '+widget.roomId+', peerId: '+widget.peerId);
    _client = ChatClient(
      userId: widget.myId,
      roomId: widget.roomId,
      peerId: widget.peerId,
    );
    _client!.isLanMode = widget.wsMode == 'lan';
    
    // 先设置 onMessage 回调，再connect
    _client!._onMessage = (data) {
      print("[P2PChat][onMessage] 收到WebSocket消息: $data");
      try {
        final obj = jsonDecode(data);
        print("[P2PChat][onMessage] 解码后: $obj");
        final msgType = obj['type'];
        final msgRoom = obj['room'];
        final myRoom = widget.roomId;
        final msgFrom = obj['from'];
        print('[P2PChat][onMessage] type: $msgType, room: $msgRoom, myRoom: $myRoom, from: $msgFrom, myId: ${widget.myId}');
        if ((msgType == 'text' || msgType == 'message')) {
          if (msgRoom == myRoom) {
            // 过滤掉自己发送的消息（本地已渲染过）
            if (msgFrom == widget.myId) {
              print("[P2PChat][onMessage] 自己发送的消息，已本地渲染，跳过");;
              return;
            }
            setState(() {
              messages.add({
                "type": "text",
                "text": obj['body'],
                "isMe": false,
                "from": msgFrom,
                "ts": obj['ts'] ?? ""
              });
            });
            print("[P2PChat][onMessage] 对方消息已渲染, 当前总数: ${messages.length}, 最新: ${obj['body']}");
            _scrollToBottom();
          } else {
            print('[P2PChat][onMessage][WARN] 房间号不符, msgRoom=$msgRoom, myRoom=$myRoom, 忽略消息');
          }
        } else {
          print("[P2PChat][onMessage] 忽略非文本消息: type=$msgType, room=$msgRoom");
        }
      } catch (e) {
        print("[P2PChat][onMessage][ERROR] 解码消息异常: $e");
      }
    };
    
    await _client!.connect();
    print('[P2PChat][_initClient] 已连接WebSocket, wsUrl: '+_client!._wsUrl);
    
    // 监听连接状态变化
    _client!._onConnectionStateChanged = (isConnected) {
      setState(() {
        _connected = isConnected;
      });
      print('[P2PChat][_initClient] 连接状态: $_connected');
    };
    
    setState(() {
      _connected = true;
    });
  }

  Future<void> _sendText() async {
    if (_controller.text.trim().isEmpty || _client == null) return;
    setState(() { _sending = true; });
    final text = _controller.text.trim();
    final ts = DateTime.now().toIso8601String();
    setState(() {
      messages.add({
        "type": "text",
        "text": text,
        "isMe": true,
        "from": widget.myId,
        "ts": ts
      });
      _controller.clear();
    });
    try {
      await _client!.sendText(text, ts: ts);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文本消息发送失败: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
      );
    } finally {
      setState(() { _sending = false; });
    }
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && _client != null) {
      setState(() { _sending = true; });
      try {
        setState(() {
          messages.add({
            "type": "image",
            "path": picked.path,
            "isMe": true,
          });
        });
        Uint8List imageBytes = await File(picked.path).readAsBytes();
        await _client!.sendImage(imageBytes, format: 'jpeg', quality: 75);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片发送成功'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片发送失败: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
        );
      } finally {
        setState(() { _sending = false; });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('[P2PChat][build] 渲染P2PChatPage, 消息数: ${messages.length}');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text('与${widget.peerName} P2P聊天')),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _connected ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _connected ? '已连接' : '未连接',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg["isMe"] ?? false;
                print('[P2PChat][build] 渲染消息 index=$index, text=${msg["text"]}, isMe=$isMe, from=${msg["from"]}');
                return ChatBubble(
                  text: msg["text"] ?? "",
                  isMe: isMe,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sending ? null : _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_sending,
                    decoration: const InputDecoration(hintText: '输入消息...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sending ? null : _sendText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== 分片/压缩/二进制图片发送 ========== 
class ChatClient {
  static const int CHUNK_SIZE = 64 * 1024; // 64KB per chunk
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  static const int RECONNECT_DELAY_MS = 2000;
  
  dynamic _ws; // WebSocket or WebSocketChannel
  bool isLanMode = true;
  final String userId;
  final String roomId;
  final String peerId;
  Function(dynamic)? _onMessage;
  Function(bool)? _onConnectionStateChanged; // 连接状态变化回调
  int _reconnectAttempts = 0;

  ChatClient({required this.userId, required this.roomId, required this.peerId});

  String get _wsUrl => isLanMode ? AppConfig.wsUrl : AppConfig.wssUrl;

  Future<void> connect() async {
    if (_ws != null) {
      print('[ChatClient][connect] WebSocket已连接，跳过重复连接');
      return;
    }
    
    try {
      print('[ChatClient][connect] 开始连接, wsUrl: $_wsUrl');
        _ws = WebSocketChannel.connect(Uri.parse(_wsUrl));
        _ws.stream.listen((msg) => _onMessage?.call(msg), onDone: _onDone, onError: _onError, cancelOnError: false);
        _ws.sink.add(jsonEncode({"type": "join", "room": roomId, "from": userId}));
      _reconnectAttempts = 0;
      _onConnectionStateChanged?.call(true);
      print('[ChatClient][connect] 连接成功');
    } catch (e) {
      print('[ChatClient][connect][ERROR] 连接失败: $e');
      _onConnectionStateChanged?.call(false);
      _reconnect();
    }
  }

  void _reconnect() async {
    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      print('[ChatClient][_reconnect] 重连次数超过上限，放弃重连');
      return;
    }
    _reconnectAttempts++;
    print('[ChatClient][_reconnect] 准备重连 (第 $_reconnectAttempts 次)，延迟 ${RECONNECT_DELAY_MS}ms');
    await Future.delayed(Duration(milliseconds: RECONNECT_DELAY_MS));
    _ws = null;
    await connect();
  }

  void _onDone() {
    print('[ChatClient][_onDone] WebSocket 连接已关闭');
    _ws = null;
    _onConnectionStateChanged?.call(false);
    _reconnect();
  }

  void _onError(error) {
    print('[ChatClient][_onError] WebSocket 错误: $error');
    _ws = null;
    _onConnectionStateChanged?.call(false);
    _reconnect();
  }

  void disconnect() {
    if (_ws == null) return;
    print('[ChatClient][disconnect] 断开连接');
    _reconnectAttempts = MAX_RECONNECT_ATTEMPTS; // 禁用自动重连
    if (kIsWeb) {
      _ws.sink.close();
    } else {
      _ws.sink.close();
    }
    _ws = null;
    _onConnectionStateChanged?.call(false);
  }

  Future<void> sendText(String text, {String? ts}) async {
    if (_ws == null) {
      print('[ChatClient][sendText] WebSocket 未连接，尝试重新连接');
      await connect();
    }
    final msg = {
      "type": "text",
      "room": roomId,
      "from": userId,
      "to": peerId,
      "body": text,
      "ts": ts ?? DateTime.now().toIso8601String()
    };
    try {
      if (kIsWeb) {
        _ws.sink.add(jsonEncode(msg));
      } else {
        _ws.sink.add(jsonEncode(msg));
      }
      print('[ChatClient][sendText] 消息已发送: $text');
    } catch (e) {
      print('[ChatClient][sendText][ERROR] 发送失败: $e');
      _reconnect();
      throw e;
    }
  }

  Future<void> sendImage(Uint8List imageBytes, {String format = "jpeg", int quality = 75}) async {
    if (_ws == null) await connect();
    Uint8List compressed = imageBytes;
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        format: format == "png" ? CompressFormat.png : CompressFormat.jpeg,
      );
      if (result.isNotEmpty) compressed = Uint8List.fromList(result);
    } catch (e) {
      print("[ChatClient][sendImage] 压缩失败，使用原始: $e");
    }
    final imageId = Uuid().v4();
    final totalSize = compressed.length;
    final totalChunks = (totalSize ~/ ChatClient.CHUNK_SIZE) + ((totalSize % ChatClient.CHUNK_SIZE) > 0 ? 1 : 0);
    final header = {
      "type": "image_header",
      "room": roomId,
      "from": userId,
      "imageId": imageId,
      "format": format,
      "size": totalSize,
      "chunks": totalChunks,
      "ts": DateTime.now().toIso8601String()
    };
    if (kIsWeb) {
      _ws.sink.add(jsonEncode(header));
    } else {
      _ws.sink.add(jsonEncode(header));
    }
    for (int i = 0; i < totalChunks; i++) {
      final start = i * ChatClient.CHUNK_SIZE;
      final end = (start + ChatClient.CHUNK_SIZE < totalSize) ? start + ChatClient.CHUNK_SIZE : totalSize;
      final chunk = compressed.sublist(start.toInt(), end.toInt());
      final chunkHeader = jsonEncode({
        "type": "image_chunk",
        "imageId": imageId,
        "index": i,
        "chunks": totalChunks,
        "room": roomId,
        "from": userId
      });
      if (kIsWeb) {
        _ws.sink.add(chunkHeader);
        _ws.sink.add(chunk);
      } else {
        _ws.sink.add(chunkHeader);
        _ws.sink.add(chunk);
      }
      await Future.delayed(Duration(milliseconds: 5));
    }
    final finish = {
      "type": "image_end",
      "imageId": imageId,
      "room": roomId,
      "from": userId,
      "ts": DateTime.now().toIso8601String()
    };
    if (kIsWeb) {
      _ws.sink.add(jsonEncode(finish));
    } else {
      _ws.sink.add(jsonEncode(finish));
    }
  }
}
