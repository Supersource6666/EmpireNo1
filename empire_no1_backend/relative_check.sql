-- SQLite
SELECT * FROM users;
.tables
select name from sqlite_master where type='table';

select * from friend_requests;

select * from messages;
--  where (from_id = 'user1' AND to_id = 'user2') OR (from_id = 'user2' AND to_id = 'user1') ORDER BY timestamp ASC;

DELETE FROM friend_requests;
DELETE FROM group_members;
DELETE FROM messages;
DELETE FROM friends;
DELETE FROM groups;
DELETE FROM users;

DELETE FROM sqlite_sequence WHERE name='friend_requests';
DELETE FROM sqlite_sequence WHERE name='group_members';
DELETE FROM sqlite_sequence WHERE name='messages';
DELETE FROM sqlite_sequence WHERE name='friends';
DELETE FROM sqlite_sequence WHERE name='groups';
DELETE FROM sqlite_sequence WHERE name='users';