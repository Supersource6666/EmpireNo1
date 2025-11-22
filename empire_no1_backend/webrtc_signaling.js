// WebRTC 信令逻辑层（可与 server.js 合并或独立）
// 用于聊天室和P2P聊天的信令转发

// 示例信令消息结构：
// { type: 'signal', signalType: 'offer|answer|candidate', from: 'userId', to: 'userId', room: 'roomId', data: {...} }

// 在 server.js 的 ws.on('message') 里已支持信令转发，只需客户端按上述格式发送即可。
// 可根据需要扩展为单独的信令路由或房间管理。
