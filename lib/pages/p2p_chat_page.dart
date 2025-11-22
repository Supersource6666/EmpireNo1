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
// 移除web平台相关导入，移动端/桌面用dart:io和web_socket_channel/io.dart

class P2PChatPage extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String wsMode; // "lan" or "remote"
  const P2PChatPage({required this.peerId, required this.peerName, required this.wsMode, Key? key}) : super(key: key);

  @override
  State<P2PChatPage> createState() => _P2PChatPageState();
}

class _P2PChatPageState extends State<P2PChatPage> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();

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
    // 假设 userId 为 'me'，peerId 为 widget.peerId
    final url = Uri.parse('http://192.168.1.104:3000/api/history?user1=me&user2=${widget.peerId}');
    try {
      final client = HttpClient();
      final req = await client.getUrl(url);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final obj = jsonDecode(body);
      if (obj['success'] == true && obj['messages'] is List) {
        setState(() {
          for (var msg in obj['messages']) {
            messages.add({
              "type": "text",
              "text": msg['body'],
              "isMe": msg['from'] == 'me',
            });
          }
        });
      }
    } catch (e) {
      // 可选：错误提示
    }
  }

  void _initClient() async {
    _client = ChatClient(
      userId: 'me', // 可替换为实际用户ID
      roomId: widget.peerId,
    );
    _client!.isLanMode = widget.wsMode == 'lan';
    await _client!.connect();
    setState(() {
      _connected = true;
    });
    _client!._onMessage = (data) {
      if (data is String) {
        final obj = jsonDecode(data);
        if (obj['type'] == 'text') {
          setState(() {
            messages.add({
              "type": "text",
              "text": obj['body'],
              "isMe": obj['from'] == 'me',
            });
          });
        }
      }
    };
  }

  Future<void> _sendText() async {
    if (_controller.text.trim().isEmpty || _client == null) return;
    setState(() { _sending = true; });
    try {
      await _client!.sendText(_controller.text.trim());
      setState(() {
        messages.add({
          "type": "text",
          "text": _controller.text.trim(),
          "isMe": true,
        });
        _controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文本消息发送成功'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文本消息发送失败: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
      );
    } finally {
      setState(() { _sending = false; });
    }
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('与${widget.peerName} P2P聊天')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg["isMe"] ?? false;
                    return Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.lightBlueAccent : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: msg["type"] == "text"
                              ? Text(
                                  msg["text"] ?? "",
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                                )
                              : msg["type"] == "image"
                                  ? Image.file(
                                      File(msg["path"]),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
                if (_sending)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.08),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('正在发送...', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
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
  final String lanWs = "ws://192.168.1.104:3000";
  final String remoteWs = "wss://yourserver.example.com:443";
  final String userId;
  final String roomId;
  Function(dynamic)? _onMessage;

  ChatClient({required this.userId, required this.roomId});

  String get _wsUrl => isLanMode ? lanWs : remoteWs;

  Future<void> connect() async {
    if (_ws != null) return;
    _ws = await WebSocket.connect(_wsUrl);
    _ws.listen(_onMessage, onDone: _onDone, onError: _onError, cancelOnError: true);
    // 加入房间
    _ws.add(jsonEncode({"type": "join", "room": roomId, "from": userId}));
  }

  void _onDone() {
    _ws = null;
  }

  void _onError(error) {
    _ws = null;
  }

  void disconnect() {
    if (_ws == null) return;
    _ws.close();
    _ws = null;
  }

  Future<void> sendText(String text) async {
    if (_ws == null) await connect();
    final msg = {
      "type": "text",
      "room": roomId,
      "from": userId,
      "body": text,
      "ts": DateTime.now().toIso8601String()
    };
    _ws.add(jsonEncode(msg));
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
    _ws.add(jsonEncode(header));
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
      _ws.add(chunkHeader);
      _ws.add(chunk);
      await Future.delayed(Duration(milliseconds: 5));
    }
    final finish = {
      "type": "image_end",
      "imageId": imageId,
      "room": roomId,
      "from": userId,
      "ts": DateTime.now().toIso8601String()
    };
    _ws.add(jsonEncode(finish));
  }
}
