import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_djlive/features/auth/data/models/user_profile.dart';

import '../../../../core/network/socket_service.dart';
import '../../../../core/utils/permission_helper.dart';
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
      // Timer(Duration(seconds: 2), () {
      //   _deleteRoom();
      // });
    } else {
      _createRoom();
      _currentRoomId = null;
      _showSnackBar('You are not in a room', Colors.red);
    }
  }

  final SocketService _socketService = SocketService.instance;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentRoomId;
  List<String> _availableRooms = [];
  String? _errorMessage;
  String? userId;
  bool isHost = false;
  String roomId = "DJLiveRoom";

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
        if (!(userId != null)) {
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
      print("User joined: $userName , console from UI");
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
        print("Available rooms: $_availableRooms from Frontend");
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

  //Agora SDK
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  final List<int> _remoteUsers = [];
  bool _muted = false;
  bool _cameraEnabled = true;
  int _viewerCount = 0;

  Future<void> initAgora() async {
    // retrieve permissions
    PermissionHelper.hasLiveStreamPermissions().then((hasPermissions) {
      if (!hasPermissions) {
        PermissionHelper.requestLiveStreamPermissions().then((granted) {
          if (!granted) {
            if (mounted) {
              PermissionHelper.showPermissionDialog(context);
            }
          }
        });
      }
    });

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: dotenv.env['AGORA_APP_ID'] ?? '',
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
            _remoteUid = connection.localUid;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            _remoteUsers.add(remoteUid);
            _viewerCount = _remoteUsers.length;
          });

          // Update viewer count in Firestore
          if (isHost) {
            // _firestoreService.updateViewerCount(widget.streamId, _viewerCount);
          }
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("remote user $remoteUid left channel");
              setState(() {
                _remoteUid = null;
                _remoteUsers.remove(remoteUid);
                _viewerCount = _remoteUsers.length;
              });

              // Update viewer count in Firestore
              if (isHost) {
                // _firestoreService.updateViewerCount(
                //   widget.streamId,
                //   _viewerCount,
                // );
              }
            },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
            '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token',
          );
        },
      ),
    );

    await _engine.setClientRole(
      role: isHost
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: dotenv.env['AGORA_TOKEN'] ?? '',
      channelId: dotenv.env['DEFAULT_CHANNEL'] ?? roomId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // Toggle microphone
  void _toggleMute() async {
    await _engine.muteLocalAudioStream(!_muted);
    setState(() {
      _muted = !_muted;
    });
  }

  // Toggle camera
  void _toggleCamera() async {
    await _engine.muteLocalVideoStream(!_cameraEnabled);
    setState(() {
      _cameraEnabled = !_cameraEnabled;
    });
  }

  // Switch camera
  void _switchCamera() async {
    await _engine.switchCamera();
  }

  // End live stream
  void _endLiveStream() async {
    try {
      if (isHost) {
        // Update stream status to not live
        // await _firestoreService.updateLiveStream(widget.streamId, {
        //   'isLive': false,
        // });
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Still navigate back even if update fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // Here you can handle the pop event, if needed
        print('Back navigation invoked: $didPop');
      },
      child: Scaffold(
        body: Stack(
          children: [

            _buildBottomControls(),
            if(false)
            SingleChildScrollView(
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
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue[700],
                            ),
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
          ],
        ),
      ),
    );
  }

  
  // Main video view
  Widget _buildVideoView() {
    if (isHost) {
      // Show local video for broadcaster
      return _localUserJoined
          ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      // Show remote video for viewers
      return _remoteVideo();
    }
  }

   Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: "default_channel"),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }


    // Bottom controls for broadcaster
  Widget _buildBottomControls() {
    if (!isHost) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: .7), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _muted ? Icons.mic_off : Icons.mic,
                color: _muted ? Colors.red : Colors.white,
                size: 28,
              ),
            ),

            // Camera toggle
            IconButton(
              onPressed: _toggleCamera,
              icon: Icon(
                _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                color: _cameraEnabled ? Colors.white : Colors.red,
                size: 28,
              ),
            ),

            // Switch camera
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 28,
              ),
            ),

            // End stream
            IconButton(
              onPressed: _endLiveStream,
              icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  

  @override
  void dispose() {
    _titleController.dispose();
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }
}
