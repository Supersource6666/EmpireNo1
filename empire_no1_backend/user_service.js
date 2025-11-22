// 用户服务层（可扩展为数据库持久化）
const db = require('./db');
const { v4: uuidv4 } = require('uuid');

function register(username, password, callback) {
  const id = uuidv4();
  db.run(
    'INSERT INTO users (id, username, password) VALUES (?, ?, ?)', 
    [id, username, password], 
    function (err) {
      if (err) return callback(err);
      callback(null, { id, username });
    }
  );
}

function login(username, password, callback) {
  db.get(
    'SELECT id, username FROM users WHERE username = ? AND password = ?',
    [username, password],
    function (err, row) {
      if (err) return callback(err);
      if (!row) return callback(null, null);
      callback(null, row);
    }
  );
}

function saveMessage(from, to, body, ts, callback) {
  db.run(
    'INSERT INTO messages (from_user, to_user, body, ts) VALUES (?, ?, ?, ?)',
    [from, to, body, ts],
    function (err) {
      callback(err);
    }
  );
}

function getHistory(user1, user2, callback) {
  db.all(
    `SELECT * FROM messages WHERE (from_user = ? AND to_user = ?) OR (from_user = ? AND to_user = ?) ORDER BY ts ASC`,
    [user1, user2, user2, user1],
    function (err, rows) {
      callback(err, rows);
    }
  );
}

function searchUser(nickname, callback) {
  db.all('SELECT id, username FROM users WHERE username LIKE ?', [`%${nickname}%`], callback);
}

function addFriend(userId, friendId, callback) {
  db.run('INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?, ?)', [userId, friendId], callback);
}

function getFriends(userId, callback) {
  db.all('SELECT u.id, u.username FROM friends f JOIN users u ON f.friend_id = u.id WHERE f.user_id = ?', [userId], callback);
}

function createOrJoinGroup(code, userId, callback) {
  db.get('SELECT id FROM groups WHERE code = ?', [code], function(err, group) {
    if (err) return callback(err);
    if (group) {
      // 已有群，加入
      db.run('INSERT OR IGNORE INTO group_members (group_id, user_id) VALUES (?, ?)', [group.id, userId], function(e) {
        callback(e, group.id);
      });
    } else {
      // 新建群
      const groupId = require('uuid').v4();
      db.run('INSERT INTO groups (id, code, name) VALUES (?, ?, ?)', [groupId, code, `群聊${code}`], function(e) {
        if (e) return callback(e);
        db.run('INSERT INTO group_members (group_id, user_id) VALUES (?, ?)', [groupId, userId], function(e2) {
          callback(e2, groupId);
        });
      });
    }
  });
}

function getGroupMembers(groupId, callback) {
  db.all('SELECT u.id, u.username FROM group_members gm JOIN users u ON gm.user_id = u.id WHERE gm.group_id = ?', [groupId], callback);
}

function sendFriendRequest(fromUser, toUser, callback) {
  db.run('INSERT INTO friend_requests (from_user, to_user, ts) VALUES (?, ?, ?)', [fromUser, toUser, new Date().toISOString()], callback);
}

function getFriendRequests(userId, callback) {
  db.all('SELECT * FROM friend_requests WHERE to_user = ? AND status = "pending"', [userId], callback);
}

function handleFriendRequest(requestId, accept, callback) {
  db.get('SELECT * FROM friend_requests WHERE id = ?', [requestId], function(err, req) {
    if (err || !req) return callback(err || new Error('请求不存在'));
    db.run('UPDATE friend_requests SET status = ? WHERE id = ?', [accept ? 'accepted' : 'rejected', requestId], function(e) {
      if (accept) {
        // 双方加为好友
        addFriend(req.from_user, req.to_user, function(e2) {
          callback(e2);
        });
      } else {
        callback(e);
      }
    });
  });
}

module.exports = { register, login, saveMessage, getHistory, searchUser, addFriend, getFriends, createOrJoinGroup, getGroupMembers, sendFriendRequest, getFriendRequests, handleFriendRequest };
