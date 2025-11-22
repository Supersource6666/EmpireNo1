import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'p2p_chat_page.dart';
import '../config.dart';

class ChatRoomPage extends StatefulWidget {
	const ChatRoomPage({super.key});

	@override
	State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
	final List<Map<String, dynamic>> messages = [];
	final TextEditingController _controller = TextEditingController();

	WebSocketChannel? _wsChannel;
	bool _wsConnected = false;

	String _username = "访客";
	String _userId = ""; // 新增字段
	bool _isLoggedIn = false;
	String _wsMode = "lan";
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
		// 固定顺序，保证双方roomId一致
		return myId.compareTo(peerId) < 0 ? '${myId}_$peerId' : '${peerId}_$myId';
	}

	@override
	void didChangeDependencies() {
		super.didChangeDependencies();
		_fetchFriends();
		_fetchFriendRequests();
		if (_isLoggedIn) {
			_connectWebSocket();
		}
	}

	@override
	void dispose() {
		_wsChannel?.sink.close();
		super.dispose();
	}

	void _connectWebSocket() {
		if (_wsChannel != null) return;
		final wsUrl = _wsMode == 'lan'
				? 'ws://${AppConfig.wsHost}:${AppConfig.wsPort}'
				: 'wss://yourserver.example.com:443';
		try {
			_wsChannel = IOWebSocketChannel.connect(wsUrl);
			_wsChannel!.sink.add(
				jsonEncode({"type": "join", "from": _userId, "room": _userId}),
			);
			_wsChannel!.stream.listen((data) {
				_handleWsMessage(data);
			}, onDone: () {
				_wsConnected = false;
				_wsChannel = null;
			}, onError: (e) {
				_wsConnected = false;
				_wsChannel = null;
			});
			_wsConnected = true;
		} catch (e) {
			_wsConnected = false;
			_wsChannel = null;
		}
	}

	void _handleWsMessage(dynamic data) {
	try {
		final msg = jsonDecode(data);
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
		}
	} catch (e) {}
	}

	Future<void> _fetchFriends() async {
		if (!_isLoggedIn) return;
		final url = Uri.parse('$_apiBaseUrl/api/friends?userId=$_userId');
		try {
			final response = kIsWeb
				? await http.get(url)
				: await http.get(url);
			final respBody = response.body;
			final List<dynamic> data = jsonDecode(respBody);
			setState(() {
				users = data.map((e) => {"id": e["id"], "name": e["username"]}).toList();
			});
		} catch (e) {}
	}

	Future<void> _fetchFriendRequests() async {
		if (!_isLoggedIn) return;
		final url = Uri.parse('$_apiBaseUrl/api/friend_requests?userId=$_userId');
		try {
			final response = kIsWeb
				? await http.get(url)
				: await http.get(url);
			final respBody = response.body;
			final List<dynamic> data = jsonDecode(respBody);
			setState(() {
				_friendRequests = data.cast<Map<String, dynamic>>();
			});
		} catch (e) {}
	}

	Future<void> _handleFriendRequest(int requestId, bool accept) async {
		final url = Uri.parse('$_apiBaseUrl/api/handle_friend_request');
		try {
			final response = await http.post(url,
				headers: {'content-type': 'application/json'},
				body: jsonEncode({"requestId": requestId, "accept": accept}),
			);
			final respBody = response.body;
			if (respBody.contains('success')) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(accept ? '已接受好友申请' : '已拒绝好友申请'), backgroundColor: accept ? Colors.green : Colors.red, duration: Duration(seconds: 1)),
				);
				_fetchFriendRequests();
				if (accept) _fetchFriends();
			}
		} catch (e) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('处理异常: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
			);
		}
	}

	Future<void> _searchUser() async {
		if (_searchNickname.trim().isEmpty) return;
		final url = Uri.parse('$_apiBaseUrl/api/search_user?nickname=$_searchNickname');
		try {
			final response = await http.get(url);
			final respBody = response.body;
			final List<dynamic> data = jsonDecode(respBody);
			setState(() {
				_searchResults = data.map((e) => {"id": e["id"], "name": e["username"]}).toList();
			});
		} catch (e) {}
	}

	Future<void> _sendFriendRequest(String toUser) async {
		final url = Uri.parse('$_apiBaseUrl/api/send_friend_request');
		try {
			final response = await http.post(url,
				headers: {'content-type': 'application/json'},
				body: jsonEncode({"fromUser": _userId, "toUser": toUser}),
			);
			final respBody = response.body;
			if (respBody.contains('success')) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('好友申请已发送'), backgroundColor: Colors.blue, duration: Duration(seconds: 1)),
				);
			}
		} catch (e) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('申请异常: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
			);
		}
	}

	void _showAddFriendDialog() {
		_searchNickname = "";
		_searchResults = [];
		showDialog(
			context: context,
			builder: (context) {
				return StatefulBuilder(
					builder: (context, setStateDialog) {
						return AlertDialog(
							title: const Text('搜索昵称添加好友'),
							content: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									TextField(
										decoration: const InputDecoration(labelText: '输入昵称'),
										onChanged: (v) {
											setStateDialog(() {
												_searchNickname = v;
											});
										},
									),
									ElevatedButton(
										onPressed: () async {
											await _searchUser();
											setStateDialog(() {});
										},
										child: const Text('搜索'),
									),
									SizedBox(height: 8),
									..._searchResults.map((user) => ListTile(
										title: Text(user["name"] ?? ""),
										trailing: ElevatedButton(
											onPressed: () async {
												await _sendFriendRequest(user["id"] ?? "");
												Navigator.pop(context);
											},
											child: const Text('申请'),
										),
									)),
								],
							),
							actions: [
								TextButton(
									onPressed: () => Navigator.pop(context),
									child: const Text('关闭'),
								),
							],
						);
					},
				);
			},
		);
	}

	void _showFriendRequestsDialog() {
		_fetchFriendRequests();
		showDialog(
			context: context,
			builder: (context) {
				return StatefulBuilder(
					builder: (context, setStateDialog) {
						return AlertDialog(
							title: const Text('好友申请'),
							content: SizedBox(
								width: 300,
								child: _friendRequests.isEmpty
										? const Text('暂无好友申请')
										: Column(
												mainAxisSize: MainAxisSize.min,
												children: _friendRequests.map((req) => ListTile(
													title: Text('来自: ${req["from_user_name"] ?? req["from_user"]}'), // 优先显示name
													subtitle: Text('时间: ${req["ts"]}'),
													trailing: Row(
														mainAxisSize: MainAxisSize.min,
														children: [
															ElevatedButton(
																onPressed: () async {
																	await _handleFriendRequest(req["id"], true);
																	setStateDialog(() {
																		_friendRequests.removeWhere((r) => r["id"] == req["id"]);
																	});
																},
																child: const Text('接受'),
															),
															SizedBox(width: 8),
															ElevatedButton(
																style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
																onPressed: () async {
																	await _handleFriendRequest(req["id"], false);
																	setStateDialog(() {
																		_friendRequests.removeWhere((r) => r["id"] == req["id"]);
																	});
																},
																child: const Text('拒绝'),
															),
														],
													),
												)).toList(),
											),
							),
							actions: [
								TextButton(
									onPressed: () => Navigator.pop(context),
									child: const Text('关闭'),
								),
							],
						);
					},
				);
			},
		);
	}

	void _showGroupDialog() {
		_groupCode = "";
		_groupMembers = [];
		showDialog(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: const Text('创建/加入群聊'),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							TextField(
								decoration: const InputDecoration(labelText: '输入4位验证码'),
								maxLength: 4,
								onChanged: (v) {
									_groupCode = v;
								},
							),
							ElevatedButton(
								onPressed: () async {
									if (_groupCode.length == 4 && _isLoggedIn) {
										final url = Uri.parse('$_apiBaseUrl/api/group');
										try {
											final response = await http.post(url,
												headers: {'content-type': 'application/json'},
											body: jsonEncode({"code": _groupCode, "userId": _userId}),
											);
											final groupId = jsonDecode(response.body)["groupId"];
											// 获取群成员
											final url2 = Uri.parse('$_apiBaseUrl/api/group_members?groupId=$groupId');
											final response2 = await http.get(url2);
											final List<dynamic> members = jsonDecode(response2.body);
											setState(() {
												_groupMembers = members.map((e) => {"id": e["id"], "name": e["username"]}).toList();
											});
										} catch (e) {
											ScaffoldMessenger.of(context).showSnackBar(
												SnackBar(content: Text('群聊异常: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
											);
										}
									}
								},
								child: const Text('创建/加入'),
							),
							SizedBox(height: 8),
							..._groupMembers.map((user) => ListTile(
								title: Text(user["name"] ?? ""),
							)),
						],
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.pop(context),
							child: const Text('关闭'),
						),
					],
				);
			},
		);
	}

	void _sendMessage() {
		if (_controller.text.trim().isEmpty) return;
		setState(() {
			messages.add({
				"user": _username,
				"text": _controller.text.trim(),
				"time": TimeOfDay.now().format(context),
				"avatar": "https://q1.qlogo.cn/g?b=qq&nk=10003&s=100",
			});
			_controller.clear();
		});
	}

	void _showSettingsDialog() {
		String tempUsername = _username;
		String tempPassword = _password;
		String tempWsMode = _wsMode;
		showDialog(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: const Text('聊天室设置'),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							TextField(
								decoration: const InputDecoration(labelText: '用户名'),
								controller: TextEditingController(text: tempUsername),
								onChanged: (v) => tempUsername = v,
							),
							TextField(
								decoration: const InputDecoration(labelText: '密码'),
								obscureText: true,
								controller: TextEditingController(text: tempPassword),
								onChanged: (v) => tempPassword = v,
							),
							const SizedBox(height: 10),
							Row(
								children: [
									ElevatedButton(
										onPressed: () async {
										if (tempUsername.isNotEmpty && tempPassword.isNotEmpty) {
											final url = Uri.parse('$_apiBaseUrl/api/register');
											try {
												final response = await http.post(url,
													headers: {'content-type': 'application/json'},
												body: jsonEncode({"username": tempUsername, "password": tempPassword}),
												);
												final respBody = jsonDecode(response.body);
												if (respBody['success'] == true && respBody['user'] != null) {
													setState(() {
														_username = tempUsername;
														_password = tempPassword;
														_isLoggedIn = true;
														_wsMode = tempWsMode;
														_userId = respBody['user']['id'];
														_wsChannel?.sink.close();
														_wsChannel = null;
													});
													Navigator.pop(context);
													ScaffoldMessenger.of(context).showSnackBar(
														const SnackBar(content: Text('注册成功，已登录'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
													);
													_fetchFriends();
													_fetchFriendRequests();
													_connectWebSocket();
												} else {
													ScaffoldMessenger.of(context).showSnackBar(
														const SnackBar(content: Text('注册失败'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
													);
												}
											} catch (e) {
												ScaffoldMessenger.of(context).showSnackBar(
													SnackBar(content: Text('注册异常: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
												);
											}
										}
									},
									child: const Text('注册'),
								),
								const SizedBox(width: 12),
								ElevatedButton(
									onPressed: () async {
									if (tempUsername.isNotEmpty && tempPassword.isNotEmpty) {
										final url = Uri.parse('$_apiBaseUrl/api/login');
										try {
											final response = await http.post(url,
												headers: {'content-type': 'application/json'},
											body: jsonEncode({"username": tempUsername, "password": tempPassword}),
											);
											final respBody = jsonDecode(response.body);
											if (respBody['success'] == true && respBody['user'] != null) {
												setState(() {
													_username = tempUsername;
													_password = tempPassword;
													_isLoggedIn = true;
													_wsMode = tempWsMode;
													_userId = respBody['user']['id'];
													_wsChannel?.sink.close();
													_wsChannel = null;
												});
												Navigator.pop(context);
												ScaffoldMessenger.of(context).showSnackBar(
													const SnackBar(content: Text('登录成功'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
												);
												_fetchFriends();
												_fetchFriendRequests();
												_connectWebSocket();
											} else {
												ScaffoldMessenger.of(context).showSnackBar(
													const SnackBar(content: Text('登录失败'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
												);
											}
										} catch (e) {
											ScaffoldMessenger.of(context).showSnackBar(
												SnackBar(content: Text('登录异常: $e'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
											);
										}
									}
								},
								child: const Text('登录'),
								),
								const SizedBox(width: 12),
								ElevatedButton(
									onPressed: () {
									setState(() {
										_username = "访客";
										_password = "";
										_isLoggedIn = false;
										_userId = "";
										_wsChannel?.sink.close();
										_wsChannel = null;
									});
									Navigator.pop(context);
									ScaffoldMessenger.of(context).showSnackBar(
										const SnackBar(content: Text('已切换为访客'), backgroundColor: Colors.blue, duration: Duration(seconds: 1)),
									);
									_fetchFriends();
									_fetchFriendRequests();
								},
								child: const Text('切换访客'),
								),
							],
						),
						const SizedBox(height: 10),
						DropdownButtonFormField<String>(
							value: tempWsMode,
							decoration: const InputDecoration(labelText: '通信模式'),
							items: const [
								DropdownMenuItem(value: 'lan', child: Text('局域网通信')),
								DropdownMenuItem(value: 'remote', child: Text('远程服务器中转')),
							],
							onChanged: (v) => tempWsMode = v ?? "lan",
						),
					],
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('取消'),
					),
				],
			);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('模拟聊天室'),
				actions: [
					IconButton(
						icon: const Icon(Icons.settings),
						onPressed: _showSettingsDialog,
					),
					IconButton(
						icon: const Icon(Icons.person_add),
						onPressed: _showAddFriendDialog,
					),
					Stack(
						children: [
							IconButton(
								icon: const Icon(Icons.mail_outline),
								onPressed: _showFriendRequestsDialog,
							),
							if (_friendRequests.isNotEmpty)
								Positioned(
									right: 6,
									top: 6,
									child: Container(
										padding: const EdgeInsets.all(2),
										decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
										constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
										child: Text(
											'${_friendRequests.length}',
											style: const TextStyle(color: Colors.white, fontSize: 12),
											textAlign: TextAlign.center,
										),
									),
								),
						],
					),
					IconButton(
						icon: const Icon(Icons.group),
						onPressed: _showGroupDialog,
					),
				],
			),
			body: Row(
				children: [
					// 好友列表
					Container(
						width: 120,
						color: Colors.white,
						child: _isLoggedIn
								? ListView.builder(
										itemCount: users.length,
										itemBuilder: (context, index) {
											final user = users[index];
											return ListTile(
												leading: CircleAvatar(child: Icon(Icons.person)), // 本地头像
												title: Text(user["name"] ?? ""),
												onTap: () {
													final roomId = getRoomId(_userId, user["id"] ?? "");
													Navigator.push(
														context,
														MaterialPageRoute(
															builder: (_) => P2PChatPage(
																peerId: user["id"] ?? "",
																peerName: user["name"] ?? "",
																wsMode: _wsMode,
																myId: _userId,
																roomId: roomId,
															),
														),
													);
												},
											);
										},
									)
								: Center(child: Text('请先登录后添加好友')),
					),
					// ...原消息区...
					Expanded(
						child: Container(
							color: const Color(0xFFEDEDED),
							child: Column(
								children: [
									Expanded(
										child: ListView.builder(
											padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
											itemCount: messages.length,
											itemBuilder: (context, index) {
												final msg = messages[index];
												final isMe = msg["user"] == _username;
												return Row(
													crossAxisAlignment: CrossAxisAlignment.start,
													mainAxisAlignment:
															isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
													children: [
														if (!isMe)
															CircleAvatar(child: Icon(Icons.person), radius: 22), // 本地头像
														if (!isMe) const SizedBox(width: 8),
														Flexible(
															child: Column(
																crossAxisAlignment:
																		isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
																children: [
																	Container(
																		padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
																		margin: const EdgeInsets.symmetric(vertical: 2),
																		decoration: BoxDecoration(
																			color: isMe ? Colors.lightBlueAccent : Colors.white,
																			borderRadius: BorderRadius.circular(18),
																			boxShadow: [
																				BoxShadow(
																					color: Colors.black12,
																					blurRadius: 2,
																					offset: Offset(0, 1),
																				),
																			],
																		),
																		child: Text(
																			msg["text"],
																			style: TextStyle(
																				color: isMe ? Colors.white : Colors.black87,
																				fontSize: 16,
																			),
																		),
																	),
																	Padding(
																		padding: const EdgeInsets.only(left: 4, right: 4),
																		child: Text(
																			"${msg["user"]} · ${msg["time"]}",
																			style: const TextStyle(fontSize: 12, color: Colors.grey),
																		),
																	),
																],
															),
														),
														if (isMe) const SizedBox(width: 8),
														if (isMe)
															CircleAvatar(child: Icon(Icons.person), radius: 22), // 本地头像
													],
												);
											},
										),
									),
									Padding(
										padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
										child: Row(
											children: [
												Expanded(
													child: TextField(
														controller: _controller,
														decoration: InputDecoration(hintText: '以${_username}身份发送消息...'),
													),
												),
												IconButton(
													icon: const Icon(Icons.send),
													onPressed: _sendMessage,
												),
											],
										),
									),
								],
							),
						),
					),
				],
			),
		);
	}
}

