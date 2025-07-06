import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dlstarlive/core/network/socket_service.dart';
import '../../features/live-streaming/data/models/room_models.dart';

/// 🎯 SOCKET SERVICE USAGE EXAMPLES
///
/// This file demonstrates how to use the SocketService in your live streaming app
/// for different scenarios like creating rooms, joining streams, and handling events.

/// Example Live Streaming Page with Socket Integration
class LiveStreamingPage extends StatefulWidget {
  final String userId;
  final String? roomId;
  final bool isHost;

  const LiveStreamingPage({
    super.key,
    required this.userId,
    this.roomId,
    this.isHost = false,
  });

  @override
  LiveStreamingPageState createState() => LiveStreamingPageState();
}

class LiveStreamingPageState extends State<LiveStreamingPage> {
  final SocketService _socketService = SocketService.instance;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentRoomId;
  RoomListResponse? _availableRooms;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  /// Initialize socket connection when entering live streaming page
  Future<void> _initializeSocket() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Connect to socket with user ID
      final connected = await _socketService.connect(widget.userId);

      if (connected) {
        _setupSocketListeners();

        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });

        // If roomId is provided, join the room
        if (widget.roomId != null) {
          await _joinRoom(widget.roomId!);
        } else if (widget.isHost) {
          // If user is host, create a new room
          await _createRoom();
        }

        // Get list of available rooms
        await _socketService.getRooms();
      } else {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Failed to connect to server';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    // Connection status
    _socketService.connectionStatusStream.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });

      if (isConnected) {
        _showSnackBar('✅ Connected to server', Colors.green);
      } else {
        _showSnackBar('❌ Disconnected from server', Colors.red);
      }
    });

    // Room events
    _socketService.roomCreatedStream.listen((roomId) {
      _showSnackBar('🏠 Room created: $roomId', Colors.blue);
      setState(() {
        _currentRoomId = roomId;
      });
    });

    _socketService.roomDeletedStream.listen((roomId) {
      _showSnackBar('🗑️ Room deleted: $roomId', Colors.orange);
      if (_currentRoomId == roomId) {
        setState(() {
          _currentRoomId = null;
        });
      }
    });

    // User events
    _socketService.userJoinedStream.listen((data) {
      final userName = data['userName'] ?? 'Unknown';
      _showSnackBar('👋 $userName joined the stream', Colors.green);
    });

    _socketService.userLeftStream.listen((data) {
      final userName = data['userName'] ?? 'Unknown';
      _showSnackBar('👋 $userName left the stream', Colors.orange);
    }); // Room list updates
    _socketService.roomListStream.listen((rooms) {
      setState(() {
        _availableRooms = rooms;
      });
    });

    // Error handling
    _socketService.errorStream.listen((error) {
      _showSnackBar('❌ Error: $error', Colors.red);
    });

    // Custom live streaming events
    _socketService.on('stream-started', (data) {
      _showSnackBar('🎥 Stream started!', Colors.green);
    });

    _socketService.on('stream-ended', (data) {
      _showSnackBar('🛑 Stream ended', Colors.red);
    });

    _socketService.on('viewer-count-updated', (data) {
      final count = data['count'] ?? 0;
      debugPrint('👥 Viewers: $count');
    });
  }

  /// Create a new room (for hosts)
  Future<void> _createRoom() async {
    final roomId =
        'room_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
    final success = await _socketService.createRoom(roomId);

    if (success) {
      setState(() {
        _currentRoomId = roomId;
      });
    }
  }

  /// Join an existing room
  Future<void> _joinRoom(String roomId) async {
    final success = await _socketService.joinRoom(roomId);

    if (success) {
      setState(() {
        _currentRoomId = roomId;
      });
    }
  }

  /// Leave current room
  Future<void> _leaveRoom() async {
    if (_currentRoomId != null) {
      final success = await _socketService.leaveRoom(_currentRoomId!);

      if (success) {
        setState(() {
          _currentRoomId = null;
        });
      }
    }
  }

  /// Delete room (only host can delete)
  Future<void> _deleteRoom() async {
    if (_currentRoomId != null && widget.isHost) {
      final success = await _socketService.deleteRoom(_currentRoomId!);

      if (success) {
        setState(() {
          _currentRoomId = null;
        });
        // Navigate back or show end screen
        _endStream();
      }
    }
  }

  /// End the stream and navigate back
  void _endStream() {
    // Additional cleanup for live streaming
    Navigator.of(context).pop();
  }

  /// Show snackbar message
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Check if user can join a specific room
  bool canUserJoinRoom(String roomId) {
    if (_availableRooms == null) return false;

    final roomData = _availableRooms!.getRoomById(roomId);
    if (roomData == null) return false;

    // User cannot join if they are banned
    if (roomData.isUserBanned(widget.userId)) return false;

    return true;
  }

  /// Get room information for display
  Map<String, dynamic>? getRoomInfo(String roomId) {
    if (_availableRooms == null) return null;

    final roomData = _availableRooms!.getRoomById(roomId);
    if (roomData == null) return null;

    return {
      'roomId': roomId,
      'hostName': roomData.hostDetails.name,
      'hostCountry': roomData.hostDetails.country,
      'memberCount': roomData.memberCount,
      'isUserHost': roomData.isUserHost(widget.userId),
      'isUserMember': roomData.isUserMember(widget.userId),
      'isUserBanned': roomData.isUserBanned(widget.userId),
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button - clean up socket
        await _cleanupSocket();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isHost ? 'Live Streaming' : 'Watching Stream'),
          backgroundColor: Colors.red,
          actions: [
            // Connection status indicator
            Container(
              margin: const EdgeInsets.all(8),
              child: CircleAvatar(
                radius: 8,
                backgroundColor: _isConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomControls(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isConnecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to server...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeSocket,
              child: Text('Retry Connection'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stream view area
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isHost ? Icons.videocam : Icons.play_circle,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.isHost ? 'You are live!' : 'Watching stream',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  if (_currentRoomId != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Room: $_currentRoomId',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Chat/Comments area
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Chat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('Chat messages will appear here'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (widget.isHost) ...[
            ElevatedButton.icon(
              onPressed: _currentRoomId != null ? _deleteRoom : null,
              icon: Icon(Icons.stop),
              label: Text('End Stream'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _currentRoomId != null ? _leaveRoom : null,
              icon: Icon(Icons.exit_to_app),
              label: Text('Leave'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],

          ElevatedButton.icon(
            onPressed: _socketService.getRooms,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
          ),

          ElevatedButton.icon(
            onPressed: () => _showRoomsList(),
            icon: Icon(Icons.list),
            label: Text('Rooms'),
          ),
        ],
      ),
    );
  }

  void _showRoomsList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Rooms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: (_availableRooms?.roomCount ?? 0) == 0
                  ? Center(child: Text('No rooms available'))
                  : ListView.builder(
                      itemCount: _availableRooms?.roomCount ?? 0,
                      itemBuilder: (context, index) {
                        final roomId = _availableRooms!.roomIds[index];
                        final roomData = _availableRooms!.getRoomById(roomId);
                        return ListTile(
                          title: Text(roomId),
                          subtitle: roomData != null
                              ? Text(
                                  'Host: ${roomData.hostDetails.name} • ${roomData.memberCount} members',
                                )
                              : null,
                          trailing: _currentRoomId == roomId
                              ? Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: _currentRoomId != roomId
                              ? () {
                                  Navigator.pop(context);
                                  _joinRoom(roomId);
                                }
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean up socket when leaving the page
  Future<void> _cleanupSocket() async {
    try {
      // Leave current room if any
      if (_currentRoomId != null) {
        await _leaveRoom();
      }

      // Disconnect socket completely
      await _socketService.disconnect();

      debugPrint('🧹 Socket cleaned up successfully');
    } catch (e) {
      debugPrint('❌ Error cleaning up socket: $e');
    }
  }

  @override
  void dispose() {
    // Clean up socket when widget is disposed
    _cleanupSocket();
    super.dispose();
  }
}

/// 📱 Example of using Socket Service in other parts of the app

/// Service class for managing live streaming operations
class LiveStreamingService {
  final SocketService _socketService = SocketService.instance;

  /// Start a live stream
  Future<String?> startLiveStream(String userId) async {
    // Connect to socket
    final connected = await _socketService.connect(userId);
    if (!connected) return null;

    // Create room
    final roomId = 'stream_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final success = await _socketService.createRoom(roomId);

    return success ? roomId : null;
  }

  /// Join a live stream
  Future<bool> joinLiveStream(String userId, String roomId) async {
    // Connect to socket
    final connected = await _socketService.connect(userId);
    if (!connected) return false;

    // Join room
    return await _socketService.joinRoom(roomId);
  }

  /// End live stream
  Future<void> endLiveStream(String roomId) async {
    await _socketService.deleteRoom(roomId);
    await _socketService.disconnect();
  }

  /// Leave live stream
  Future<void> leaveLiveStream(String roomId) async {
    await _socketService.leaveRoom(roomId);
    await _socketService.disconnect();
  }

  /// Get available streams
  Future<List<String>> getAvailableStreams(String userId) async {
    final connected = await _socketService.connect(userId);
    if (!connected) return [];

    await _socketService.getRooms();

    // Listen for rooms list
    final completer = Completer<List<String>>();

    _socketService.roomListStream.take(1).listen((rooms) {
      completer.complete(rooms.roomIds);
    });

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => [],
    );
  }
}

/// 🎯 Usage in Navigation

/// Example of navigating to live streaming page
class NavigationHelper {
  /// Navigate to host live stream
  static void goLive(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamingPage(userId: userId, isHost: true),
      ),
    );
  }

  /// Navigate to join live stream
  static void joinStream(BuildContext context, String userId, String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LiveStreamingPage(userId: userId, roomId: roomId, isHost: false),
      ),
    );
  }
}

/// 🔧 Integration with BLoC

/// Example BLoC for managing live streaming state
class LiveStreamBloc {
  final LiveStreamingService _service = LiveStreamingService();

  /// Start streaming
  Future<String?> startStream(String userId) async {
    return await _service.startLiveStream(userId);
  }

  /// Join stream
  Future<bool> joinStream(String userId, String roomId) async {
    return await _service.joinLiveStream(userId, roomId);
  }

  /// End stream
  Future<void> endStream(String roomId) async {
    await _service.endLiveStream(roomId);
  }
}
