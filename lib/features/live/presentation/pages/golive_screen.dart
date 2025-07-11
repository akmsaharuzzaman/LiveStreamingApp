import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/socket_service.dart';
import 'package:dlstarlive/core/utils/permission_helper.dart';
import 'package:dlstarlive/features/live/presentation/component/agora_token_service.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/active_viwers.dart';
import '../component/custom_live_button.dart';
import '../component/diamond_star_status.dart';
import '../component/end_stream_overlay.dart';
import '../component/game_bottomsheet.dart';
import '../component/host_info.dart';
import '../widgets/live_chat_widget.dart';

enum LiveScreenLeaveOptions { disconnect, muteCall, viewProfile }

class GoliveScreen extends StatefulWidget {
  final String? roomId;
  final String? hostName;
  final String? hostUserId;
  final String? hostAvatar;
  const GoliveScreen({
    super.key,
    this.roomId,
    this.hostName,
    this.hostUserId,
    this.hostAvatar,
  });

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

  // Live stream timing
  DateTime? _streamStartTime;
  Timer? _durationTimer;
  Duration _streamDuration = Duration.zero;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _roomCreatedSubscription;
  StreamSubscription? _roomJoinedSubscription;
  StreamSubscription? _roomLeftSubscription;
  StreamSubscription? _roomDeletedSubscription;
  StreamSubscription? _errorSubscription;

  // Chat messages
  final List<ChatMessage> _chatMessages = [];

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
    final state = context.read<AuthBloc>().state;
    final String? uid = state is AuthAuthenticated ? state.user.id : null;

    if (uid != null && uid.isNotEmpty) {
      debugPrint("Userid: $uid");
      setState(() {
        userId = uid;
        debugPrint("User ID set: $userId");
      });

      // Initialize Agora and socket AFTER userId is loaded
      await initAgoraLoad();
    } else {
      debugPrint("User ID is null, cannot initialize live streaming");
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

  /// Generate dummy chat message
  void _generateDummyMessage() {
    final random = Random();
    final dummyUsers = [
      'Habib',
      'Nasim Replay',
      'Nahid',
      'Sarah',
      'Ahmed',
      'Fatima',
      'Omar',
      'Aisha',
    ];
    final dummyMessages = [
      'how are you',
      'fine and you',
      'Joined the room',
      'Hello everyone!',
      'Great stream!',
      'Love this content',
      'Amazing performance',
      'Keep it up!',
      'Nice work',
      'Awesome!',
    ];

    final userName = dummyUsers[random.nextInt(dummyUsers.length)];
    final message = dummyMessages[random.nextInt(dummyMessages.length)];
    final level = random.nextInt(25) + 1; // Level 1-25
    final isVip =
        random.nextBool() && level > 10; // VIP more likely for higher levels

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: userName,
      message: message,
      timestamp: DateTime.now(),
      level: level,
      isVip: isVip,
    );

    setState(() {
      _chatMessages.add(newMessage);
      // Keep only last 50 messages to prevent memory issues
      if (_chatMessages.length > 50) {
        _chatMessages.removeAt(0);
      }
    });
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

          // Start timing the stream when successfully joined
          _startStreamTimer();

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

  // Start stream timer
  void _startStreamTimer() {
    _streamStartTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _streamStartTime != null) {
        setState(() {
          _streamDuration = DateTime.now().difference(_streamStartTime!);
        });
      }
    });
  }

  // Stop stream timer
  void _stopStreamTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  // Format duration to string
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // End live stream
  void _endLiveStream() async {
    try {
      // Stop the stream timer
      _stopStreamTimer();

      if (isHost) {
        // If host, delete the room
        await _deleteRoom();
      } else {
        // If viewer, leave the room
        await _leaveRoom();
      }
      if (isHost) {
        if (mounted) {
          final state = context.read<AuthBloc>().state;
          if (state is AuthAuthenticated) {
            context.go(
              AppRoutes.liveSummary,
              extra: {
                'userName': state.user.name,
                'userId': state.user.id.substring(0, 6),
                'earnedPoints': 0,
                'newFollowers': 0,
                'totalDuration': _formatDuration(_streamDuration),
                'userAvatar': state.user.avatar,
              },
            );
          }
        }
      } else {
        // If viewer, just navigate back
        if (mounted) {
          context.go("/");
        }
      }
    } catch (e) {
      debugPrint('Error ending live stream: $e');
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
        // Always trigger cleanup when back navigation is invoked
        _endLiveStream();
        debugPrint(
          'Back navigation invoked: '
          '(cleanup triggered)',
        );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Please log in to start live streaming',
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            );
          } else {
            return Scaffold(
              body: Stack(
                children: [
                  _buildVideoView(),

                  // * This contaimer holds the livestream options,
                  SafeArea(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      child: Column(
                        spacing: 15,
                        children: [
                          // this is the top row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isHost)
                                HostInfo(
                                  imageUrl:
                                      state.user.avatar ??
                                      "https://thispersondoesnotexist.com/",
                                  name: state.user.name,
                                  id: state.user.id.substring(0, 4),
                                )
                              else
                                HostInfo(
                                  imageUrl:
                                      widget.hostAvatar ??
                                      "https://thispersondoesnotexist.com/",
                                  name: widget.hostName ?? "Host",
                                  id:
                                      widget.hostUserId?.substring(0, 4) ??
                                      "Host",
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
                                            debugPrint("Keep stream pressed");
                                          },
                                          onEndStream: () {
                                            _endLiveStream();
                                            debugPrint("End stream pressed");
                                          },
                                        );
                                      },
                                      child: Image.asset(
                                        "assets/icons/live_exit_icon.png",
                                        height: 40,
                                        width: 40,
                                      ),
                                    )
                                  : InkWell(
                                      onTap: () {
                                        _endLiveStream();
                                        debugPrint("Disconnect pressed");
                                      },
                                      child: Image.asset(
                                        "assets/icons/live_exit_icon.png",
                                        height: 40,
                                        width: 40,
                                      ),
                                    ),
                            ],
                          ),

                          //  this is the second row
                          DiamondStarStatus(
                            diamonCount: "100.0k",
                            starCount: "2",
                          ),

                          Spacer(),

                          // Chat widget - positioned at bottom left
                          Align(
                            alignment: Alignment.centerLeft,
                            child: LiveChatWidget(messages: _chatMessages),
                          ),

                          const SizedBox(height: 10),

                          // the bottom buttons
                          if (isHost)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                CustomLiveButton(
                                  iconPath: "assets/icons/chat_icon.png",
                                  onTap: () {
                                    _generateDummyMessage();
                                    // _showSnackBar(
                                    //   '💬 Message added to chat!',
                                    //   Colors.green,
                                    // );
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/call_icon.png",
                                  onTap: () {
                                    _showSnackBar(
                                      '📞 Not implemented yet! Comming soon!',
                                      Colors.green,
                                    );
                                    // showCallBottomSheet(context);
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: _muted
                                      ? "assets/icons/mute_icon.png"
                                      : "assets/icons/mute_icon.png",
                                  onTap: () {
                                    !isHost
                                        ? _showSnackBar(
                                            '🎤 You cannot mute yourself as host',
                                            Colors.orange,
                                          )
                                        : _toggleMute();
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/gift_icon.png",
                                  onTap: () {
                                    _showSnackBar(
                                      '🎁 Not implemented yet',
                                      Colors.green,
                                    );
                                    // showGiftBottomSheet(context);
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/pk_icon.png",
                                  onTap: () {
                                    _showSnackBar(
                                      '🎶 Not implemented yet',
                                      Colors.green,
                                    );
                                    // showMusicBottomSheet(context);
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/music_icon.png",
                                  onTap: () {
                                    _showSnackBar(
                                      '🎶 Not implemented yet',
                                      Colors.green,
                                    );
                                    // showMusicBottomSheet(context);
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/threedot_icon.png",
                                  onTap: () {
                                    showGameBottomSheet(
                                      context,
                                      userId: userId,
                                      isHost: isHost,
                                    );
                                  },
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () {
                                    _showSnackBar(
                                      '💬 Not implemented yet',
                                      Colors.green,
                                    );
                                    // showChatBottomSheet(context);
                                  },
                                  child: Stack(
                                    children: [
                                      Image.asset(
                                        "assets/icons/message_icon.png",
                                        height: 40,
                                        width: 170,
                                      ),
                                      Positioned(
                                        left: 10,
                                        top: 0,
                                        bottom: 0,
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              "assets/icons/message_user_icon.png",
                                              height: 25,
                                              width: 25,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Say Hi..',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/gift_user_icon.png",
                                  onTap: () {},
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/game_user_icon.png",
                                  onTap: () {
                                    showGameBottomSheet(
                                      context,
                                      userId: userId,
                                    );
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/share_user_icon.png",
                                  onTap: () {},
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/menu_icon.png",
                                  onTap: () {},
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
          }
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

    // Stop the duration timer
    _stopStreamTimer();

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

const List<Map<String, String>> activeViewers = [];

void generateActiveViewers(int count) {
  activeViewers.clear();
  for (int i = 0; i < count; i++) {
    activeViewers.add({
      'dp': 'https://thispersondoesnotexist.com/',
      'follower': '${(i + 1) * 100}K',
    });
  }
}
