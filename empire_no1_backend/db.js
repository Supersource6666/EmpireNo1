const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dbPath = path.join(__dirname, 'empire_no1.db');
const db = new sqlite3.Database(dbPath);

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE,
    password TEXT
  )`);
  db.run(`CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_user TEXT,
    to_user TEXT,
    body TEXT,
    ts TEXT
  )`);
  db.run(`CREATE TABLE IF NOT EXISTS friends (
    user_id TEXT,
    friend_id TEXT,
    UNIQUE(user_id, friend_id)
  )`);
  db.run(`CREATE TABLE IF NOT EXISTS groups (
    id TEXT PRIMARY KEY,
    code TEXT,
    name TEXT
  )`);
  db.run(`CREATE TABLE IF NOT EXISTS group_members (
    group_id TEXT,
    user_id TEXT,
    UNIQUE(group_id, user_id)
  )`);
  db.run(`CREATE TABLE IF NOT EXISTS friend_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_user TEXT,
    to_user TEXT,
    status TEXT DEFAULT 'pending',
    ts TEXT
  )`);
});

module.exports = db;
