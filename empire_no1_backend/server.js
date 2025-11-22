// EmpireNo1 后端主入口
// 1. 用户注册/登录接口（REST API）
// 2. 聊天室与P2P聊天（WebRTC信令+ws）

const express = require('express');
const bodyParser = require('body-parser');
const { register, login, saveMessage, getHistory, searchUser, addFriend, getFriends, createOrJoinGroup, getGroupMembers, sendFriendRequest, getFriendRequests, handleFriendRequest } = require('./user_service');
const { v4: uuidv4 } = require('uuid');
const WebSocket = require('ws');
const http = require('http');

const app = express();
// 允许CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*'); // 或指定你的web页面IP
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});


app.use(bodyParser.json());

// 用户注册
app.post('/api/register', (req, res) => {
  const { username, password } = req.body;
  register(username, password, (err, user) => {
    if (err) return res.status(400).json({ error: '注册失败', detail: err.message });
    res.json({ success: true, user });
  });
});

// 用户登录
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  login(username, password, (err, user) => {
    if (err) return res.status(500).json({ error: '登录失败', detail: err.message });
    if (!user) return res.status(401).json({ error: '用户名或密码错误' });
    res.json({ success: true, user });
  });
});

// 查询双方历史消息
app.get('/api/history', (req, res) => {
  const { user1, user2 } = req.query;
  if (!user1 || !user2) return res.status(400).json({ error: '参数缺失' });
  getHistory(user1, user2, (err, rows) => {
    if (err) return res.status(500).json({ error: '查询失败', detail: err.message });
    res.json({ success: true, messages: rows });
  });
});

app.get('/api/search_user', (req, res) => {
  const { nickname } = req.query;
  searchUser(nickname, (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/api/add_friend', (req, res) => {
  const { userId, friendId } = req.body;
  addFriend(userId, friendId, (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

app.get('/api/friends', (req, res) => {
  const { userId } = req.query;
  getFriends(userId, (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/api/group', (req, res) => {
  const { code, userId } = req.body;
  createOrJoinGroup(code, userId, (err, groupId) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ groupId });
  });
});

app.get('/api/group_members', (req, res) => {
  const { groupId } = req.query;
  getGroupMembers(groupId, (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// 存储所有用户的 WebSocket 连接
const userSockets = {};

app.post('/api/send_friend_request', (req, res) => {
  const { fromUser, toUser } = req.body;
  sendFriendRequest(fromUser, toUser, (err) => {
    if (err) return res.status(500).json({ error: err.message });
    // WebSocket 推送
    if (userSockets[toUser] && userSockets[toUser].readyState === WebSocket.OPEN) {
      userSockets[toUser].send(JSON.stringify({
        type: 'friend_request',
        from: fromUser
      }));
    }
    res.json({ success: true });
  });
});

app.get('/api/friend_requests', (req, res) => {
  const { userId } = req.query;
  getFriendRequests(userId, (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/api/handle_friend_request', (req, res) => {
  const { requestId, accept } = req.body;
  handleFriendRequest(requestId, accept, (err, fromUserId, toUserId) => {
    if (err) return res.status(500).json({ error: err.message });
    // 通知双方刷新好友列表
    [fromUserId, toUserId].forEach(uid => {
      if (userSockets[uid] && userSockets[uid].readyState === WebSocket.OPEN) {
        userSockets[uid].send(JSON.stringify({ type: 'friend_update' }));
      }
    });
    res.json({ success: true });
  });
});

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// 房间和用户管理
const rooms = {};

wss.on('connection', (ws, req) => {
  let userId = null;
  let roomId = null;
  console.log('[WebSocket] 新连接，当前连接数:', wss.clients.size);

  ws.on('message', (message) => {
    let data;
    try {
      data = JSON.parse(message);
    } catch (e) {
      console.log('[WebSocket][ERROR] JSON解析失败:', e.message);
      ws.send(JSON.stringify({ error: 'Invalid JSON' }));
      return;
    }
    console.log('[WebSocket] 收到消息:', JSON.stringify(data));
    if (data.type === 'join') {
      userId = data.from || uuidv4();
      roomId = data.room;
      if (!rooms[roomId]) rooms[roomId] = {};
      rooms[roomId][userId] = ws;
      // 记录用户 WebSocket
      userSockets[userId] = ws;
      console.log('[WebSocket][join] 用户加入: userId='+userId+', roomId='+roomId+', 房间内用户数: '+Object.keys(rooms[roomId]).length);
      // 广播用户列表
      broadcast(roomId, {
        type: 'user_list',
        users: Object.keys(rooms[roomId])
      });
    } else if (data.type === 'signal') {
      // P2P信令转发
      const target = data.target;
      if (rooms[roomId] && rooms[roomId][target]) {
        rooms[roomId][target].send(JSON.stringify({
          type: 'signal',
          from: userId,
          signal: data.signal
        }));
      }
    } else if (data.type === 'message' || data.type === 'text') {
      // 统一广播 type: 'text'，并补充 ts 字段
      console.log('[WebSocket][message] userId='+userId+', roomId='+roomId+', body='+data.body+', 房间内用户数: '+(rooms[roomId] ? Object.keys(rooms[roomId]).length : 0));
      broadcast(roomId, {
        type: 'text',
        from: userId,
        body: data.body,
        room: roomId,
        ts: new Date().toISOString()
      });
      // Save the message to the database
      if (data.to) {
        saveMessage(userId, data.to, data.body, new Date().toISOString(), () => {});
      }
    }
  });

  ws.on('close', () => {
    if (roomId && userId && rooms[roomId]) {
      delete rooms[roomId][userId];
      broadcast(roomId, {
        type: 'user_list',
        users: Object.keys(rooms[roomId])
      });
    }
    // 移除用户 WebSocket
    if (userId && userSockets[userId] === ws) {
      delete userSockets[userId];
    }
  });
});

function broadcast(roomId, msg) {
  if (!rooms[roomId]) {
    console.log('[broadcast] 房间不存在: '+roomId);
    return;
  }
  const clientCount = Object.keys(rooms[roomId]).length;
  console.log('[broadcast] roomId='+roomId+', 房间内用户数: '+clientCount+', 消息类型: '+msg.type);
  Object.entries(rooms[roomId]).forEach(([userId, client]) => {
    if (client.readyState === WebSocket.OPEN) {
      console.log('[broadcast] 向用户 '+userId+' 转发消息');
      client.send(JSON.stringify(msg));
    } else {
      console.log('[broadcast] 用户 '+userId+' 连接已关闭，状态: '+client.readyState);
    }
  });
}

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';
server.listen(PORT, HOST, () => {
  console.log(`EmpireNo1 backend running on http://${HOST}:${PORT}`);
});
