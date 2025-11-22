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

  ws.on('message', (message) => {
    let data;
    try {
      data = JSON.parse(message);
    } catch (e) {
      ws.send(JSON.stringify({ error: 'Invalid JSON' }));
      return;
    }
    if (data.type === 'join') {
      userId = data.from || uuidv4();
      roomId = data.room;
      if (!rooms[roomId]) rooms[roomId] = {};
      rooms[roomId][userId] = ws;
      // 记录用户 WebSocket
      userSockets[userId] = ws;
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
      // Ensure the room field is included in the broadcasted message
      broadcast(roomId, {
        type: data.type,
        from: userId,
        body: data.body,
        room: roomId // Add the room field explicitly
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
  if (!rooms[roomId]) return;
  Object.values(rooms[roomId]).forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(msg));
    }
  });
}

const PORT = 3000;
server.listen(PORT, () => {
  console.log(`EmpireNo1 backend running on port ${PORT}`);
});
