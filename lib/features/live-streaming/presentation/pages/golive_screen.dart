import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dlstarlive/features/live-streaming/presentation/component/agora_token_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/socket_service.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../component/active_viwers.dart';
import '../component/custom_live_button.dart';
import '../component/diamond_star_status.dart';
import '../component/end_stream_overlay.dart';
import '../component/game_bottomsheet.dart';
import '../component/gift_bottom_sheet.dart';
import '../component/host_info.dart';
import '../component/live_screen_menu_button.dart';

enum LiveScreenLeaveOptions { disconnect, muteCall, viewProfile }

class GoliveScreen extends StatefulWidget {
  final String? roomId;
  const GoliveScreen({super.key, this.roomId});

  @override
  State<GoliveScreen> createState() => _GoliveScreenState();
}

class _GoliveScreenState extends State<GoliveScreen> {
  final TextEditingController _titleController = TextEditingController();

  final SocketService _socketService = SocketService.instance;
  String? _currentRoomId;
  String? userId;
  bool isHost = true;
  String roomId = "default_channel";

  // Stream subscriptions for proper cleanup
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _roomCreatedSubscription;
  StreamSubscription? _roomJoinedSubscription;
  StreamSubscription? _roomLeftSubscription;
  StreamSubscription? _roomDeletedSubscription;
  StreamSubscription? _errorSubscription;
  @override
  void initState() {
    super.initState();
    extractRoomId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndDispatchEvent();
    });
  }

  void extractRoomId() {
    if (widget.roomId != null && widget.roomId!.isNotEmpty) {
      roomId = widget.roomId!;
      isHost = false;
      debugPrint("Extracted room ID: $roomId");
    } else {
      isHost = true; // Default to host if no room ID provided
      // Don't set roomId here - it will be set dynamically using userId when creating room
      debugPrint("No room ID provided, will create dynamic room with userId");
    }
  }

  Future<void> initAgoraLoad() async {
    try {
      // _showSnackBar('🚀 Setting up live stream...', Colors.blue);
      debugPrint('🚀 Setting up live stream...');
      await initAgora();
      // _showSnackBar('📡 Connecting to server...', Colors.blue);
      debugPrint('📡 Connecting to server...');
      await _initializeSocket();
      _setupSocketListeners();
      // _showSnackBar('✅ Live stream ready!', Colors.green);
      debugPrint('✅ Live stream ready!');
    } catch (e) {
      debugPrint('❌ Error in initAgoraLoad: $e');
      _showSnackBar('❌ Failed to setup live stream', Colors.red);
    }
  }

  Future<void> _loadUidAndDispatchEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('uid');

    if (uid != null && uid.isNotEmpty) {
      debugPrint("Userid: $uid");
      setState(() {
        userId = uid;
        debugPrint("User ID set: $userId");
        context.read<ProfileBloc>().add(ProfileEvent.userDataLoaded(uid: uid));
      });

      // Initialize Agora and socket AFTER userId is loaded
      await initAgoraLoad();
    } else {
      debugPrint("No UID found");
      debugPrint("User ID is null, cannot initialize live streaming");
      // _showSnackBar('❌ User authentication required', Colors.red);
    }
  }

  /// Initialize socket connection when entering live streaming page
  Future<void> _initializeSocket() async {
    try {
      // Connect to socket with user ID
      final connected = await _socketService.connect(userId!);

      if (connected) {
        _setupSocketListeners();

        // If roomId is provided, join the room
        if (isHost) {
          await _createRoom();
        } else {
          await _joinRoom(roomId);
        }

        // Get list of available rooms
        await _socketService.getRooms();
      } else {
        debugPrint('Failed to connect to server');
        // _showSnackBar('❌ Failed to connect to server', Colors.red);
      }
    } catch (e) {
      debugPrint('Connection error: $e');
      // _showSnackBar('❌ Connection error', Colors.red);
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    // Connection status
    debugPrint("Setting up socket listeners");
    _connectionStatusSubscription = _socketService.connectionStatusStream
        .listen((isConnected) {
          if (mounted) {
            if (isConnected) {
              // _showSnackBar('✅ Connected to server', Colors.green);
              debugPrint("Connected to server");
            } else {
              // _showSnackBar('❌ Disconnected from server', Colors.red);
              debugPrint("Disconnected from server");
            }
          }
        });

    // Room events
    _roomCreatedSubscription = _socketService.roomCreatedStream.listen((
      roomId,
    ) {
      if (mounted) {
        // _showSnackBar('🏠 Room created: $roomId', Colors.blue);
        debugPrint("🏠 Room created: $roomId");
        setState(() {
          _currentRoomId = roomId;
        });
      }
    });

    _roomDeletedSubscription = _socketService.roomDeletedStream.listen((
      roomId,
    ) {
      if (mounted) {
        // _showSnackBar('🗑️ Room deleted: $roomId', Colors.orange);
        debugPrint("🗑️ Room deleted: $roomId");
        if (_currentRoomId == roomId) {
          setState(() {
            _currentRoomId = null;
          });
        }
      }
    });

    // User events
    _socketService.userJoinedStream.listen((data) {
      if (mounted) {
        final userName = data['userName'] ?? 'Unknown';
        debugPrint("User joined: $userName , console from UI");
        // _showSnackBar('👋 $userName joined the stream', Colors.green);
        debugPrint("👋 $userName joined the stream");
      }
    });

    _socketService.userLeftStream.listen((data) {
      if (mounted) {
        final userName = data['userName'] ?? 'Unknown';
        // _showSnackBar('👋 $userName left the stream', Colors.orange);
        debugPrint("👋 $userName left the stream");
      }
    }); // Room list updates
    _socketService.roomListStream.listen((rooms) {
      if (mounted) {
        debugPrint("Available rooms: ${rooms.roomIds} from Frontend");
      }
    });

    // Error handling
    _errorSubscription = _socketService.errorStream.listen((error) {
      if (mounted) {
        // _showSnackBar('❌ Error: $error', Colors.red);
        debugPrint("Error from socket: $error");
      }
    });

    // Custom live streaming events
    _socketService.on('stream-started', (data) {
      if (mounted) {
        // _showSnackBar('🎥 Stream started!', Colors.green);
        debugPrint("🎥 Stream started!");
      }
    });

    _socketService.on('stream-ended', (data) {
      if (mounted) {
        // _showSnackBar('🛑 Stream ended', Colors.red);
        debugPrint("🛑 Stream ended");
      }
    });

    _socketService.on('viewer-count-updated', (data) {
      final count = data['count'] ?? 0;
      debugPrint('👥 Viewers: $count');
    });
  }

  /// Create a new room (for hosts)
  Future<void> _createRoom() async {
    if (userId == null) {
      debugPrint('❌ Cannot create room: userId is null');
      // _showSnackBar('❌ User not authenticated', Colors.red);
      return;
    }

    // Use userId as the room name for dynamic room creation
    final dynamicRoomId = userId!;
    debugPrint('🏠 Creating room with dynamic name: $dynamicRoomId');

    final success = await _socketService.createRoom(dynamicRoomId);

    if (success) {
      setState(() {
        _currentRoomId = dynamicRoomId;
        roomId = dynamicRoomId; // Update the roomId for Agora channel
      });
      debugPrint('✅ Room created successfully: $dynamicRoomId');
      // _showSnackBar('🏠 Room created: $dynamicRoomId', Colors.green);

      // Now join the Agora channel with the dynamic room ID
      await _joinChannelWithDynamicToken();
    } else {
      debugPrint('❌ Failed to create room: $dynamicRoomId');
      // _showSnackBar('❌ Failed to create room', Colors.red);
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
  int _viewerCount = 0;
  bool _isInitializingCamera = false;

  Future<void> initAgora() async {
    try {
      setState(() {
        _isInitializingCamera = true;
      });

      // Check permissions FIRST and wait for the result
      bool hasPermissions = await PermissionHelper.hasLiveStreamPermissions();

      if (!hasPermissions) {
        debugPrint('⚠️ Live streaming permissions not granted, requesting...');
        _showSnackBar(
          '📹 Camera and microphone permissions required',
          Colors.orange,
        );

        // Request permissions and wait for the result
        bool granted = await PermissionHelper.requestLiveStreamPermissions();
        if (!granted) {
          debugPrint('❌ Live streaming permissions denied');
          _showSnackBar(
            '❌ Cannot start live stream without permissions',
            Colors.red,
          );
          if (mounted) {
            PermissionHelper.showPermissionDialog(context);
          }
          setState(() {
            _isInitializingCamera = false;
          });
          // Don't initialize Agora if permissions not granted
          return;
        }
      }

      // Only initialize Agora AFTER permissions are confirmed
      debugPrint('✅ Permissions granted, initializing Agora engine...');
      // _showSnackBar('🎥 Initializing camera...', Colors.blue);
      debugPrint('🎥 Initializing camera...');

      //create the engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(
        RtcEngineContext(
          appId: dotenv.env['AGORA_APP_ID'] ?? '',
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      setState(() {
        _isInitializingCamera = false;
      });
    } catch (e) {
      debugPrint('❌ Error in initAgora: $e');
      _showSnackBar('❌ Failed to initialize live streaming', Colors.red);
      setState(() {
        _isInitializingCamera = false;
      });
      return;
    }

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint(
            "local user ${connection.localUid} joined channel: ${connection.channelId}",
          );
          setState(() {
            _localUserJoined = true;
            // Don't set _remoteUid here - it should only be set when a remote user joins
          });

          // Show success message
          if (isHost) {
            // _showSnackBar('🎥 Live stream started!', Colors.green);
            debugPrint('🎥 Live stream started!');
          } else {
            // _showSnackBar('📺 Connected to stream!', Colors.green);
            debugPrint('📺 Connected to stream!');
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint(
            "remote user $remoteUid joined channel: ${connection.channelId}",
          );
          debugPrint("Current isHost: $isHost, _remoteUid before: $_remoteUid");
          setState(() {
            _remoteUid = remoteUid;
            _remoteUsers.add(remoteUid);
            _viewerCount = _remoteUsers.length;
          });
          debugPrint(
            "_remoteUid after: $_remoteUid, total users: ${_remoteUsers.length}",
          );

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
                // Only set _remoteUid to null if it was the user who left
                if (_remoteUid == remoteUid) {
                  _remoteUid = null;
                }
                _remoteUsers.remove(remoteUid);
                _viewerCount = _remoteUsers.length;
                generateActiveViewers(_viewerCount);
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

    // Only start preview for broadcasters
    if (isHost) {
      await _engine.startPreview();
    }

    // For viewers, join channel immediately
    // For hosts, wait for room creation to set dynamic roomId
    if (!isHost) {
      await _joinChannelWithDynamicToken();
    }
  }

  /// Generate dynamic token and join Agora channel
  Future<void> _joinChannelWithDynamicToken() async {
    try {
      if (userId == null) {
        debugPrint('User ID is null, cannot generate token');
        _showSnackBar('❌ User not authenticated', Colors.red);
        return;
      }

      // _showSnackBar('🔑 Generating access token...', Colors.blue);
      debugPrint('🔑 Generating access token...');

      // Generate token using the API
      // final result = await _liveStreamService.generateAgoraToken(
      //   channelName: roomId, // Use the room ID as channel name
      //   uid: userId!, // Use the user ID
      // );
      final result = await AgoraTokenService.getRtcToken(
        channelName: roomId,
        role: isHost ? 'publisher' : 'subscriber',
      );
      debugPrint('💲💲Token generation result new: ${result.token}');
      if (result.token.isNotEmpty) {
        final dynamicToken = result.token;
        debugPrint('✅ Token generated successfully : $dynamicToken');

        // _showSnackBar('📡 Joining live stream...', Colors.blue);
        debugPrint('📡 Joining live stream...');

        // Join channel with dynamic token
        await _engine.joinChannel(
          token: dynamicToken,
          channelId: roomId, // Use the room ID as channel
          uid: 0, // Let Agora assign UID
          options: const ChannelMediaOptions(),
        );
      } else {
        debugPrint('Failed to generate token: ${result.success}');
        _showSnackBar(
          '❌ Token generation failed, using fallback',
          Colors.orange,
        );
        // Fallback to static token
        await _joinChannelWithStaticToken();
      }
    } catch (e) {
      debugPrint('Error generating token: $e');
      _showSnackBar('❌ Connection error, using fallback', Colors.orange);
      // Fallback to static token
      await _joinChannelWithStaticToken();
    }
  }

  /// Fallback method to join with static token
  Future<void> _joinChannelWithStaticToken() async {
    debugPrint('Using fallback static token');
    await _engine.joinChannel(
      token: dotenv.env['AGORA_TOKEN'] ?? '',
      channelId: dotenv.env['DEFAULT_CHANNEL'] ?? 'default_channel',
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

  // End live stream
  void _endLiveStream() async {
    try {
      if (isHost) {
        // If host, delete the room
        await _deleteRoom();
      } else {
        // If viewer, leave the room
        await _leaveRoom();
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
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // Here you can handle the pop event, if needed
        print('Back navigation invoked: $didPop');
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return Scaffold(
            body: Stack(
              children: [
                _buildVideoView(),

                // * This contaimer holds the livestream options,
                SafeArea(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      spacing: 15,
                      children: [
                        // this is the top row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // *shows user informations
                            HostInfo(
                              imageUrl: "https://thispersondoesnotexist.com/",
                              name:
                                  state.userProfile.result?.name ?? "Host Name",
                              id:
                                  state.userProfile.result?.id?.substring(
                                    0,
                                    4,
                                  ) ??
                                  "Host ID",
                            ),

                            // *show the viwers
                            ActiveViewers(activeUserList: activeViewers),

                            // * to show the leave button
                            (isHost)
                                ? GestureDetector(
                                    onTap: () {
                                      EndStreamOverlay.show(
                                        context,
                                        onKeepStream: () {
                                          print("Keep stream pressed");
                                        },
                                        onEndStream: () {
                                          _endLiveStream();
                                          print("End stream pressed");
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  )
                                : LiveScreenMenuButton(
                                    onDisconnect: () {
                                      _endLiveStream();
                                      print("Disconnect pressed");
                                    },
                                    onMuteCall: () {
                                      print("Mute call pressed");
                                      _toggleMute();
                                    },
                                    onViewProfile: () {
                                      print("View profile pressed");
                                    },
                                  ),
                          ],
                        ),

                        //  this is the second row
                        DiamondStarStatus(
                          diamonCount: "100.0k",
                          starCount: "2",
                        ),

                        Spacer(),

                        // the bottom buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            CustomLiveButton(
                              icon: Icons.chat_bubble_outline,
                              onTap: () {},
                            ),
                            CustomLiveButton(icon: Icons.call, onTap: () {}),
                            CustomLiveButton(
                              icon: _muted ? Icons.mic_off : Icons.mic,
                              onTap: () {
                                _toggleMute();
                              },
                            ),
                            CustomLiveButton(
                              icon: Icons.redeem,
                              onTap: () {
                                showGiftBottomSheet(context);
                              },
                            ),
                            CustomLiveButton(
                              icon: Icons.music_note,
                              onTap: () {},
                            ),
                            CustomLiveButton(
                              icon: Icons.more_vert,
                              onTap: () {
                                showGameBottomSheet(context, userId: userId);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // _buildBottomControls(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Main video view
  Widget _buildVideoView() {
    debugPrint(
      "Building video view - isHost: $isHost, _localUserJoined: $_localUserJoined, _remoteUid: $_remoteUid, _isInitializingCamera: $_isInitializingCamera",
    );

    // Show loading indicator during camera initialization
    if (_isInitializingCamera) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 20),
              Text(
                '🎥 Initializing camera...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Please wait while we set up your stream',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (isHost) {
      // Show local video for broadcaster
      return _localUserJoined
          ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
          : Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      '📡 Connecting to stream...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
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
          connection: RtcConnection(channelId: roomId), // Use dynamic roomId
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 20),
              Text(
                '📡 Waiting for broadcaster...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'The stream will start soon',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent setState calls after disposal
    _connectionStatusSubscription?.cancel();
    _roomCreatedSubscription?.cancel();
    _roomJoinedSubscription?.cancel();
    _roomLeftSubscription?.cancel();
    _roomDeletedSubscription?.cancel();
    _errorSubscription?.cancel();

    // Dispose other resources
    _titleController.dispose();
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }
}

const activeViewers = [];

void generateActiveViewers(int count) {
  activeViewers.clear();
  for (int i = 0; i < count; i++) {
    activeViewers.add({
      'dp': 'https://thispersondoesnotexist.com/',
      'follower': '${(i + 1) * 100}K',
    });
  }
}
