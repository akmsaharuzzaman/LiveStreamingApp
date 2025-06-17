import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_djlive/features/auth/data/models/user_profile.dart';

import '../../../../core/network/socket_service.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';

class GoliveScreen extends StatefulWidget {
  const GoliveScreen({super.key});

  @override
  State<GoliveScreen> createState() => _GoliveScreenState();
}

class _GoliveScreenState extends State<GoliveScreen> {
  final TextEditingController _titleController = TextEditingController();
  // final StorageService _storageService = StorageService();
  bool _isLoading = false;

  void _goLive() async {
    _initializeSocket();
    _setupSocketListeners();
  }

  void _checkRoom() {
    if (_currentRoomId != null) {
      _showSnackBar(
        'You are already in a room: $_currentRoomId',
        Colors.orange,
      );
      _createRoom();
      Timer(Duration(seconds: 2), () {
        _deleteRoom();
      });
    } else {
      _createRoom();
    }
  }

  final SocketService _socketService = SocketService.instance;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentRoomId;
  List<String> _availableRooms = [];
  String? _errorMessage;
  String? userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndDispatchEvent();
    });
    _initializeSocket();
  }

  Future<void> _loadUidAndDispatchEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('uid');

    if (uid != null && uid.isNotEmpty) {
      debugPrint("Userid: $uid");
      setState(() {
        userId = uid;
      });
    } else {
      debugPrint("No UID found");
    }
  }

  /// Initialize socket connection when entering live streaming page
  Future<void> _initializeSocket() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Connect to socket with user ID
      final connected = await _socketService.connect(userId!);

      if (connected) {
        _setupSocketListeners();

        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });

        // If roomId is provided, join the room
        if (userId != null) {
          await _joinRoom(userId!);
        } else if (true) {
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
    print("Setting up socket listeners");
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
    });

    // Room list updates
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
    // final roomId = 'room_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final roomId = userId;
    final success = await _socketService.createRoom(roomId!);

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
    if (_currentRoomId != null && userId != null) {
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
    // Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (canPop, result) {
        // Handle back navigation
        if (_isConnected) {
          _leaveRoom();
          _endStream();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Go Live'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Set up your live stream',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a thumbnail and title for your stream',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _goLive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_fill, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'You are ready to go live',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_fill, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'Check Room Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Tips Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for a great stream',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Choose an eye-catching thumbnail\n'
                      '• Write a descriptive title\n'
                      '• Make sure you have good lighting\n'
                      '• Test your internet connection',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
