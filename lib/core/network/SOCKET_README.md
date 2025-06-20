# 🔥 Socket Service for Live Streaming

A comprehensive, production-ready Socket.IO service for Flutter live streaming applications with automatic connection management and real-time event handling.

## 📁 Files Structure

```
lib/core/network/
├── socket_service.dart        # Main socket service class
└── socket_usage_examples.dart # Complete usage examples
```

## ✨ Features

- **🔌 Auto Connection Management**: Connect/disconnect with lifecycle management
- **🏠 Room Operations**: Create, join, leave, delete rooms
- **📡 Real-time Events**: Live streaming events and user interactions
- **🔄 Auto Reconnection**: Automatic reconnection with retry logic
- **📊 Stream Management**: Broadcast events with type-safe streams
- **🛡️ Error Handling**: Comprehensive error handling and logging
- **💾 State Management**: Track connection and room states
- **🧹 Auto Cleanup**: Automatic cleanup when leaving pages

## 🚀 Quick Start

### 1. Add Dependency

The `socket_io_client` dependency has been added to your `pubspec.yaml`:

```yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

Run: `flutter pub get`

### 2. Basic Usage

```dart
final socketService = SocketService.instance;

// Connect when entering live stream page
await socketService.connect('user123');

// Create room (for hosts)
await socketService.createRoom('room123');

// Join room (for viewers)
await socketService.joinRoom('room123');

// Disconnect when leaving page
await socketService.disconnect();
```

## 🎯 Live Streaming Page Integration

### Complete Page Example

```dart
class LiveStreamPage extends StatefulWidget {
  final String userId;
  final bool isHost;
  
  @override
  _LiveStreamPageState createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  final SocketService _socketService = SocketService.instance;
  
  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }
  
  Future<void> _initializeSocket() async {
    // Connect to socket
    final connected = await _socketService.connect(widget.userId);
    
    if (connected) {
      _setupListeners();
      
      if (widget.isHost) {
        // Create room for host
        await _socketService.createRoom('room_${widget.userId}');
      }
    }
  }
  
  void _setupListeners() {
    // Listen to connection status
    _socketService.connectionStatusStream.listen((isConnected) {
      setState(() {
        // Update UI based on connection
      });
    });
    
    // Listen to user events
    _socketService.userJoinedStream.listen((data) {
      print('User joined: ${data['userName']}');
    });
    
    _socketService.userLeftStream.listen((data) {
      print('User left: ${data['userName']}');
    });
  }
  
  @override
  void dispose() {
    // Auto cleanup when leaving page
    _socketService.disconnect();
    super.dispose();
  }
}
```

## 📡 Event Handling

### Listen to Socket Events

```dart
// Connection events
socketService.connectionStatusStream.listen((isConnected) {
  if (isConnected) {
    print('✅ Connected to server');
  } else {
    print('❌ Disconnected from server');
  }
});

// Room events
socketService.roomCreatedStream.listen((roomId) {
  print('🏠 Room created: $roomId');
});

socketService.userJoinedStream.listen((data) {
  print('👋 ${data['userName']} joined');
});

// Error handling
socketService.errorStream.listen((error) {
  print('❌ Socket error: $error');
});
```

### Custom Events

```dart
// Listen to custom events
socketService.on('viewer-count-updated', (data) {
  final count = data['count'];
  print('👥 Viewers: $count');
});

// Emit custom events
socketService.emit('send-message', {
  'message': 'Hello everyone!',
  'userId': 'user123',
});
```

## 🏠 Room Management

### Host Operations

```dart
// Create room
final roomId = 'stream_${userId}_${timestamp}';
await socketService.createRoom(roomId);

// Delete room (only host)
await socketService.deleteRoom(roomId);

// Get room list
await socketService.getRooms();
```

### Viewer Operations

```dart
// Join room
await socketService.joinRoom('room123');

// Leave room
await socketService.leaveRoom('room123');

// Listen for room updates
socketService.roomListStream.listen((rooms) {
  print('Available rooms: $rooms');
});
```

## 🔄 Connection Lifecycle

### Auto-Initialize on Page Entry

```dart
@override
void initState() {
  super.initState();
  _connectSocket();
}

Future<void> _connectSocket() async {
  final connected = await SocketService.instance.connect(userId);
  if (connected) {
    // Setup listeners and join/create rooms
  }
}
```

### Auto-Cleanup on Page Exit

```dart
@override
void dispose() {
  // Socket automatically cleans up:
  // 1. Leaves current room
  // 2. Disconnects from server
  // 3. Closes all streams
  SocketService.instance.disconnect();
  super.dispose();
}
```

### Handle Back Button

```dart
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      // Clean up socket before leaving
      await SocketService.instance.disconnect();
      return true;
    },
    child: Scaffold(
      // Your UI here
    ),
  );
}
```

## 🎮 Advanced Usage

### Service Layer Integration

```dart
class LiveStreamingService {
  final SocketService _socketService = SocketService.instance;
  
  Future<String?> startStream(String userId) async {
    final connected = await _socketService.connect(userId);
    if (!connected) return null;
    
    final roomId = 'stream_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final success = await _socketService.createRoom(roomId);
    
    return success ? roomId : null;
  }
  
  Future<bool> joinStream(String userId, String roomId) async {
    final connected = await _socketService.connect(userId);
    if (!connected) return false;
    
    return await _socketService.joinRoom(roomId);
  }
}
```

### BLoC Integration

```dart
class LiveStreamBloc extends Bloc<LiveStreamEvent, LiveStreamState> {
  final SocketService _socketService = SocketService.instance;
  
  LiveStreamBloc() : super(LiveStreamInitial()) {
    on<ConnectToStreamEvent>(_onConnect);
    on<JoinRoomEvent>(_onJoinRoom);
  }
  
  Future<void> _onConnect(ConnectToStreamEvent event, Emitter emit) async {
    emit(LiveStreamConnecting());
    
    final connected = await _socketService.connect(event.userId);
    
    if (connected) {
      emit(LiveStreamConnected());
    } else {
      emit(LiveStreamError('Connection failed'));
    }
  }
}
```

## 🛡️ Error Handling

### Connection Errors

```dart
socketService.errorStream.listen((error) {
  // Show user-friendly error messages
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Connection error: $error')),
  );
});
```

### Reconnection

```dart
// Manual reconnection
if (!socketService.isConnected) {
  await socketService.reconnect();
}

// Check connection health
if (socketService.isHealthy) {
  // Connection is stable
}
```

## ⚙️ Configuration

### Update Base URL

```dart
// In socket_service.dart
static const String _baseUrl = 'http://your-server.com:8000';
```

### Custom Events

```dart
// Add custom event listeners in _setupSocketListeners()
_socket!.on('custom-event', (data) {
  // Handle custom event
});
```

## 📊 Socket Events Reference

### Built-in Events

| Event | Type | Description |
|-------|------|-------------|
| `create-room` | Emit | Create a new room |
| `delete-room` | Emit | Delete existing room |
| `join-room` | Emit | Join a room |
| `leave-room` | Emit | Leave a room |
| `get-rooms` | Emit | Get list of rooms |
| `room-created` | Listen | Room was created |
| `room-deleted` | Listen | Room was deleted |
| `user-joined` | Listen | User joined room |
| `user-left` | Listen | User left room |
| `rooms-list` | Listen | List of available rooms |

### Custom Streaming Events

| Event | Description |
|-------|-------------|
| `stream-started` | Stream broadcast started |
| `stream-ended` | Stream broadcast ended |
| `viewer-count-updated` | Live viewer count |
| `chat-message` | Chat message received |

## 🎯 Best Practices

1. **Connect Early**: Connect to socket when entering live stream page
2. **Clean Up**: Always disconnect when leaving page
3. **Error Handling**: Listen to error streams and handle gracefully
4. **State Management**: Use streams to update UI reactively
5. **Room Management**: Track current room state
6. **User Feedback**: Show connection status to users

## 📱 Navigation Integration

```dart
// Navigate to live stream page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LiveStreamPage(
      userId: currentUser.id,
      isHost: true,
    ),
  ),
);
```

## 🚀 Production Ready Features

- ✅ **Auto Reconnection**: Handles network interruptions
- ✅ **Memory Management**: Proper cleanup and disposal
- ✅ **Error Recovery**: Graceful error handling
- ✅ **State Persistence**: Maintains connection state
- ✅ **Event Broadcasting**: Type-safe event streams
- ✅ **Performance Optimized**: Efficient resource usage

## 🔧 Troubleshooting

### Connection Issues

```dart
// Check connection status
if (!socketService.isConnected) {
  print('Not connected - attempting reconnection');
  await socketService.reconnect();
}
```

### Room Issues

```dart
// Verify room state
print('Current room: ${socketService.currentRoomId}');
print('Current user: ${socketService.currentUserId}');
```

Your socket service is now ready for production use with complete live streaming functionality! 🎉

## 📞 Socket URL Format

**Base URL**: `http://dlstarlive.com:8000`
**With User ID**: `http://dlstarlive.com:8000?userId=YOUR_USER_ID`

The socket service automatically appends the userId parameter as required by your backend.
