import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:universal_io/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/html.dart';
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
    _loadHistory();
    _initClient();
  }

  void _loadHistory() async {
    final url = Uri.parse('http://${AppConfig.wsHost}:${AppConfig.wsPort}/api/history?user1=${widget.myId}&user2=${widget.peerId}');
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
    _client = ChatClient(
      userId: widget.myId,
      roomId: widget.roomId,
      peerId: widget.peerId,
    );
    _client!.isLanMode = widget.wsMode == 'lan';
    await _client!.connect();
    setState(() {
      _connected = true;
    });
    _client!._onMessage = (data) {
      print("WebSocket message received: $data"); // 增加日志，打印收到的消息
      try {
        final obj = jsonDecode(data);
        print("Decoded WebSocket message: $obj"); // 增加日志，打印解析后的消息
        if (obj['type'] == 'text' && obj['room'] == widget.roomId) {
          setState(() {
            messages.add({
              "type": "text",
              "text": obj['body'],
              "isMe": obj['from'] == widget.myId, // 判断是否是当前用户发送
              "from": obj['from'],
              "ts": obj['ts'] ?? ""
            });
          });

          // 将消息列表中的条数打印出来
          print("Message length: ${messages.length}, Latest message: ${obj['body']}, Room: ${obj['room'] ?? 'N/A'}");
          _scrollToBottom();
        } else {
          print("Message ignored: type=${obj['type']}, room=${obj['room']}"); // 增加日志，打印被忽略的消息
        }
      } catch (e) {
        print("Error decoding WebSocket message: $e"); // 增加日志，捕获解析错误
      }
    };
  }

  Future<void> _sendText() async {
    if (_controller.text.trim().isEmpty || _client == null) return;
    setState(() { _sending = true; });
    final text = _controller.text.trim();
    final ts = DateTime.now().toIso8601String();
    // 先本地渲染，后ws发送
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
    return Scaffold(
      appBar: AppBar(title: Text('与${widget.peerName} P2P聊天')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg["isMe"] ?? false;
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
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: '输入消息...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendText,
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
  dynamic _ws; // WebSocket or WebSocketChannel
  bool isLanMode = true;
  final String userId;
  final String roomId;
  final String peerId; // 新增
  Function(dynamic)? _onMessage;

  ChatClient({required this.userId, required this.roomId, required this.peerId}); // 修改

  String get _wsUrl => isLanMode ? AppConfig.wsUrl : AppConfig.wssUrl;

  Future<void> connect() async {
    if (_ws != null) return;
    if (kIsWeb) {
      _ws = HtmlWebSocketChannel.connect(_wsUrl);
      _ws.stream.listen(_onMessage, onDone: _onDone, onError: _onError, cancelOnError: true);
      _ws.sink.add(jsonEncode({"type": "join", "room": roomId, "from": userId}));
    } else {
      _ws = IOWebSocketChannel.connect(_wsUrl);
      _ws.stream.listen(_onMessage, onDone: _onDone, onError: _onError, cancelOnError: true);
      _ws.sink.add(jsonEncode({"type": "join", "room": roomId, "from": userId}));
    }
  }

  void _onDone() {
    _ws = null;
  }

  void _onError(error) {
    _ws = null;
  }

  void disconnect() {
    if (_ws == null) return;
    if (kIsWeb) {
      _ws.sink.close();
    } else {
      _ws.sink.close();
    }
    _ws = null;
  }

  Future<void> sendText(String text, {String? ts}) async {
    if (_ws == null) await connect();
    final msg = {
      "type": "text",
      "room": roomId,
      "from": userId,
      "to": peerId, // 新增，确保后端保存消息
      "body": text,
      "ts": ts ?? DateTime.now().toIso8601String()
    };
    if (kIsWeb) {
      _ws.sink.add(jsonEncode(msg));
    } else {
      _ws.sink.add(jsonEncode(msg));
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
      print("compress fail, use original: $e");
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
