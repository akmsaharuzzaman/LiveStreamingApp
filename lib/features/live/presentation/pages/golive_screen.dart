import 'dart:async';
// import 'dart:math'; // removed unused import
import 'package:flutter/foundation.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/broadcaster_model.dart';
import 'package:dlstarlive/core/network/models/call_request_list_model.dart';
import 'package:dlstarlive/core/network/models/call_request_model.dart';
import 'package:dlstarlive/core/network/models/chat_model.dart';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/socket_service.dart';
import 'package:dlstarlive/core/utils/permission_helper.dart';
import 'package:dlstarlive/features/live/presentation/component/agora_token_service.dart';
import 'package:dlstarlive/features/live/presentation/component/gift_bottom_sheet.dart';
import 'package:dlstarlive/features/live/presentation/component/send_message_buttonsheet.dart';
import 'package:dlstarlive/features/live/presentation/widgets/call_overlay_widget.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/models/admin_details_model.dart';
import '../../../../core/network/models/ban_user_model.dart';
import '../../../../core/network/models/joined_user_model.dart';
import '../../../../core/network/models/mute_user_model.dart';
import '../../../../core/utils/app_utils.dart';
import '../component/active_viwers.dart';
import '../component/custom_live_button.dart';
import '../component/diamond_star_status.dart';
import '../component/end_stream_overlay.dart';
import '../component/game_bottomsheet.dart';
import '../component/host_info.dart';
import '../component/menu_bottom_sheet.dart';
import '../widgets/animated_layer.dart';
import '../widgets/call_manage_bottom_sheet.dart';
import '../widgets/live_chat_widget.dart';

enum LiveScreenLeaveOptions { disconnect, muteCall, viewProfile }

class GoliveScreen extends StatefulWidget {
  final String? roomId;
  final String? hostName;
  final String? hostUserId;
  final String? hostAvatar;
  final List<HostDetails> existingViewers;
  const GoliveScreen({
    super.key,
    this.roomId,
    this.hostName,
    this.hostUserId,
    this.hostAvatar,
    this.existingViewers = const [],
  });

  @override
  State<GoliveScreen> createState() => _GoliveScreenState();
}

class _GoliveScreenState extends State<GoliveScreen> {
  final TextEditingController _titleController = TextEditingController();

  // Debug helper method to control logging based on debug mode
  void _debugLog(String message) {
    if (kDebugMode) {
      // Only log in debug mode, and only essential messages
      debugPrint(message);
    }
  }

  final SocketService _socketService = SocketService.instance;
  String? _currentRoomId;
  String? userId;
  bool isHost = true;
  String roomId = "default_channel";
  List<JoinedUserModel> activeViewers = [];
  List<CallRequestModel> callRequests = [];
  List<CallRequestListModel> callDetailRequest = [];
  List<String> callRequestsList = [];
  List<String> broadcasterList = [];
  List<BroadcasterModel> broadcasterModels = [];
  List<BroadcasterModel> broadcasterDetails = [];
  List<GiftModel> sentGifts = [];
  // Banned users
  List<String> bannedUsers = [];
  // Banned user details
  List<BanUserModel> bannedUserModels = [];
  // Mute user details - store only the latest mute state
  MuteUserModel? currentMuteState;
  //Admin Details
  List<AdminDetailsModel> adminModels = [];

  // Live stream timing
  DateTime? _streamStartTime;
  Timer? _durationTimer;
  Duration _streamDuration = Duration.zero;

  // Host activity tracking for viewers
  Timer? _hostActivityTimer;
  DateTime? _lastHostActivity;
  bool _animationPlaying = false;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _roomCreatedSubscription;
  StreamSubscription? _roomJoinedSubscription;
  StreamSubscription? _roomLeftSubscription;
  StreamSubscription? _roomDeletedSubscription;
  StreamSubscription? _errorSubscription;

  // Chat messages
  final List<ChatModel> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _initializeExistingViewers();
    extractRoomId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndDispatchEvent();
    });
  }

  /// Convert HostDetails to JoinedUserModel and initialize existing viewers
  void _initializeExistingViewers() {
    if (widget.existingViewers.isNotEmpty) {
      // First convert all existing viewers to JoinedUserModel
      activeViewers = widget.existingViewers.map((hostDetail) {
        return JoinedUserModel(
          id: hostDetail.id,
          avatar: hostDetail.avatar,
          name: hostDetail.name,
          uid: hostDetail.uid,
        );
      }).toList();

      // Then check if host is in the list and remove if found
      if (widget.hostUserId != null) {
        activeViewers.removeWhere((viewer) => viewer.id == widget.hostUserId);
        debugPrint(
          "Host (${widget.hostUserId}) removed from active viewers list",
        );
      }

      debugPrint(
        "Initialized ${activeViewers.length} existing viewers (host excluded)",
      );
    }
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

        // Initialize host activity monitoring for viewers
        if (!isHost) {
          _initHostActivityMonitoring();
        }

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

    // User events
    _socketService.userJoinedStream.listen((data) {
      if (mounted) {
        // Don't add host to activeViewers list (use hostUserId from widget)
        if (data.id != widget.hostUserId &&
            !activeViewers.any((user) => user.id == data.id)) {
          activeViewers.add(data);
        }
        debugPrint("User joined: ${data.name} - ${data.uid}");
      }
    });

    //Joined Call Requests List
    _socketService.joinCallRequestStream.listen((data) {
      if (mounted) {
        if (!callRequests.any((user) => user.userId == data.userId)) {
          callRequests.add(data);
          _showSnackBar(
            '📞 ${data.userDetails.name} wants to join the call',
            Colors.blue,
          );
        }
        debugPrint(
          "User request to join call: ${data.userDetails.name} - ${data.userDetails.uid}",
        );
        // Update bottom sheet if it's open
        _updateCallManageBottomSheet();
      }
    });

    _socketService.joinCallRequestListStream.listen((data) {
      if (mounted) {
        callDetailRequest = data;
        debugPrint("Call request list updated: $callDetailRequest");
        // Update bottom sheet if it's open
        _updateCallManageBottomSheet();
      }
    });

    // Sent Messages
    _socketService.sentMessageStream.listen((data) {
      if (mounted) {
        debugPrint("User sent a message: ${data.text}");
      }
      setState(() {
        _chatMessages.add(data);
      });
      if (_chatMessages.length > 50) {
        _chatMessages.removeAt(0);
      }
    });

    // Broadcaster List - in call
    _socketService.broadcasterListStream.listen((data) {
      if (mounted) {
        // Now data is already List<BroadcasterModel> from socket
        broadcasterModels = List.from(data);

        // Extract IDs for backward compatibility with existing logic
        broadcasterList = broadcasterModels.map((model) => model.id).toList();

        // Check if current user is in broadcaster list before removing (for non-host logic)
        bool wasUserInBroadcasterList = broadcasterList.contains(userId);

        // Determine host ID: for hosts it's userId, for viewers it's widget.hostUserId
        String? hostId = isHost ? userId : widget.hostUserId;

        // Update host activity timestamp for viewers
        if (!isHost && hostId != null && broadcasterList.contains(hostId)) {
          _lastHostActivity = DateTime.now();
        }

        // CHECK FOR HOST DISCONNECTION - Exit live screen if host is no longer in broadcaster list
        if (!isHost && hostId != null && !broadcasterList.contains(hostId)) {
          _handleHostDisconnection("Host disconnected. Live session ended.");
          return; // Early return to prevent further processing
        }

        // Remove ONLY the host from UI list (not current user if they're a caller)
        if (hostId != null && broadcasterList.contains(hostId)) {
          broadcasterList.remove(hostId);
          broadcasterModels.removeWhere((model) => model.id == hostId);
        }

        debugPrint("Broadcaster(caller) list updated: $broadcasterList");
        debugPrint("Host ID filtered out: $hostId");
        debugPrint("Current userId: $userId");
        debugPrint("IsHost: $isHost");
        debugPrint(
          "Broadcaster models updated: ${broadcasterModels.length} items",
        );

        // Handle non-host broadcaster status changes
        if (!isHost) {
          if (wasUserInBroadcasterList) {
            // Notify user that they are now a broadcaster
            _showSnackBar('🎤 You are now in Call', Colors.green);
            _promoteToAudioCaller();
          } else {
            debugPrint("User is not a broadcaster");
            _leaveAudioCaller();
          }
        }

        // Update bottom sheet if it's open
        _updateCallManageBottomSheet();
      }
    });

    _socketService.userLeftStream.listen((data) {
      if (mounted) {
        activeViewers.removeWhere((user) => user.id == data.id);
        debugPrint("User left: ${data.name} - ${data.uid}");
      }
    });

    //Sent Gifts
    _socketService.sentGiftStream.listen((data) {
      if (mounted) {
        setState(() {
          sentGifts.add(data);
        });
        debugPrint("User sent a gift: ${data.gift.name}");
        sentGifts.isNotEmpty ? _playAnimation() : null;
      }
    });

    //BannedUserList
    _socketService.bannedListStream.listen((data) {
      if (mounted) {
        setState(() {
          bannedUsers = List.from(data);
        });
        debugPrint("Banned user list updated: $bannedUsers");
      }
    });

    //BannedUsers
    _socketService.bannedUserStream.listen((data) {
      if (mounted) {
        setState(() {
          bannedUserModels.add(data);
        });
        debugPrint("User banned: ${data.targetId}->${data.message}");
      }
    });

    //Mute user
    _socketService.muteUserStream.listen((data) {
      if (mounted) {
        setState(() {
          // Store only the latest mute state which contains all muted users
          currentMuteState = data;
        });
        debugPrint(
          "User muted: ${data.allMutedUsersList} - ${data.lastUserIsMuted}",
        );

        // Check if current user is muted and force mute them
        if (_isCurrentUserMuted()) {
          _forceMuteCurrentUser();
        }
      }
    });

    //AdminList
    _socketService.adminDetailsStream.listen((data) {
      if (mounted) {
        setState(() {
          adminModels.add(data);
        });
        debugPrint("Admin list updated: ${adminModels.length} admins");
      }
    });

    // Room Closed - Host ended the live session
    _socketService.roomClosedStream.listen((data) {
      if (mounted) {
        _handleHostDisconnection("Live session ended by host.");
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
  }

  /// Update the CallManageBottomSheet with current data
  void _updateCallManageBottomSheet() {
    callManageBottomSheetKey.currentState?.updateData(
      newCallers: callRequests,
      newInCallList: broadcasterModels,
    );
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

    final success = await _socketService.createRoom(
      dynamicRoomId,
      "Demo Title",
      RoomType.live,
    );

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

  //Sent/Send Message
  void _emitMessageToSocket(String message) {
    if (message.isNotEmpty && _currentRoomId != null) {
      _socketService.sendMessage(_currentRoomId!, message);
    }
  }

  // Make Admin
  void _makeAdmin(String userId) {
    _socketService.makeAdmin(userId);
  }

  // Remove Admin
  void _removeAdmin(String userId) {
    _socketService.makeAdmin(userId);
  }

  /// Ban User
  void _banUser(String userId) {
    _socketService.banUser(userId);
  }

  /// Mute User
  void _muteUser(String userId) {
    _socketService.muteUser(userId);
  }

  /// Check if current user is in the muted users list
  bool _isCurrentUserMuted() {
    if (userId == null || currentMuteState == null) return false;

    // Check if current user is in the complete list of muted users
    return currentMuteState!.allMutedUsersList.contains(userId);
  }

  /// Force mute current user when they are administratively muted
  void _forceMuteCurrentUser() async {
    if ((isHost || _isAudioCaller) && !_muted) {
      try {
        await _engine.muteLocalAudioStream(true);
        setState(() {
          _muted = true;
        });
        _showSnackBar('🔇 You have been muted by an admin', Colors.red);
        debugPrint("Current user force muted by admin");
      } catch (e) {
        debugPrint('❌ Error force muting user: $e');
      }
    }
  }

  /// Check if current user is an admin
  bool _isCurrentUserAdmin() {
    if (userId == null) return false;

    for (var adminModel in adminModels) {
      if (adminModel.id == userId) {
        return true;
      }
    }
    return false;
  }

  /// Check if current user is the host
  bool _isCurrentUserHost() {
    return isHost;
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

  /// Handle host disconnection - Exit live screen with cleanup
  void _handleHostDisconnection(String reason) {
    if (!mounted) return;

    debugPrint("🚨 $reason - Exiting live screen...");
    _showSnackBar('📱 $reason', Colors.red);

    // Perform basic cleanup
    _stopStreamTimer();
    _hostActivityTimer?.cancel();

    // Small delay to show the message before navigating
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop(); // Exit the live screen
      }
    });
  }

  /// Start monitoring for host disconnection when no video broadcasters are present
  void _startHostDisconnectionMonitoring() {
    // Don't start multiple timers
    if (_hostActivityTimer != null) return;

    debugPrint(
      "🔍 No video broadcasters detected - starting 7 second countdown...",
    );

    // Wait 7 seconds before considering host disconnected
    _hostActivityTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;

      // Double check that there are still no video broadcasters
      List<int> currentBroadcasters = [
        if (_remoteUid != null) _remoteUid!,
        ..._videoCallerUids,
        if (_isAudioCaller && isCameraEnabled) 0,
      ];

      if (currentBroadcasters.isEmpty) {
        debugPrint(
          "🚨 No video broadcasters for 7 seconds - host disconnected",
        );
        _handleHostDisconnection("Host disconnected. Live session ended.");
      } else {
        debugPrint("✅ Video broadcasters detected - host reconnected");
      }

      _hostActivityTimer = null;
    });
  }

  /// Initialize host activity monitoring for viewers
  void _initHostActivityMonitoring() {
    if (isHost) return; // Only for viewers

    _lastHostActivity = DateTime.now();

    // Check host activity every 5 seconds
    _hostActivityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final lastActivity = _lastHostActivity;

      // If no activity detected for 10 seconds, consider host disconnected
      if (lastActivity != null &&
          now.difference(lastActivity).inSeconds >= 10) {
        timer.cancel();
        _handleHostDisconnection(
          "Host appears to be inactive. Live session ended.",
        );
      }
    });
  }

  //Agora SDK
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  final List<int> _remoteUsers = [];
  bool _muted = false;
  bool _isInitializingCamera = false;

  // Audio caller feature variables
  bool _isAudioCaller = false;
  final List<int> _audioCallerUids = [];
  final List<int> _videoCallerUids = []; // Track callers with video enabled
  final int _maxAudioCallers = 3;
  bool _isJoiningAsAudioCaller = false;
  bool isCameraEnabled = false;

  Future<void> _applyCameraPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Debug: List all keys to verify SharedPreferences is working
      Set<String> keys = prefs.getKeys();
      debugPrint('🔍 All SharedPreferences keys: $keys');

      bool isFrontCamera = prefs.getBool('is_front_camera') ?? true;

      debugPrint(
        '🔍 Reading camera preference from SharedPreferences (AFTER channel join):',
      );
      debugPrint('📱 Stored value: $isFrontCamera');
      debugPrint(
        '🔄 Applying camera preference: ${isFrontCamera ? 'Front' : 'Rear'} camera',
      );

      // If the saved preference is for rear camera, switch to it
      if (!isFrontCamera) {
        debugPrint('🔄 Switching to rear camera AFTER channel join...');
        await _engine.switchCamera();
        debugPrint(
          '✅ Applied camera preference: Rear camera (AFTER channel join)',
        );
      } else {
        debugPrint(
          '✅ Applied camera preference: Front camera (default - AFTER channel join)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error applying camera preference AFTER channel join: $e');
    }
  }

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
      _debugLog('✅ Permissions granted, initializing Agora engine...');
      _debugLog('🎥 Initializing camera...');

      //create the engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(
        RtcEngineContext(
          logConfig: LogConfig(
            filePath: 'agora_rtc_engine.log',
            level: LogLevel.logLevelNone,
          ),
          appId: dotenv.env['AGORA_APP_ID'] ?? '',
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      setState(() {
        _isInitializingCamera = false;
      });

      // Load camera preference and apply it
      // Moved this to after video initialization
      // await _applyCameraPreference();
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

          // Apply camera preference AFTER successfully joining the channel
          debugPrint('🔍 onJoinChannelSuccess - isHost: $isHost');
          if (isHost) {
            debugPrint(
              '🔍 Calling _applyCameraPreference() from onJoinChannelSuccess',
            );
            _applyCameraPreference();
          } else {
            debugPrint('🔍 Not applying camera preference - user is not host');
          }

          // Start timing the stream when successfully joined
          _startStreamTimer();

          // Show success message
          if (isHost) {
            _debugLog('🎥 Live stream started!');
          } else {
            _debugLog('📺 Connected to stream!');
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          // Reduced logging: only log important events
          _debugLog("User $remoteUid joined channel");

          setState(() {
            // Only set _remoteUid for the first video user (host)
            if (_remoteUid == null && !isHost) {
              _remoteUid = remoteUid;
            }
            _remoteUsers.add(remoteUid);
          });

          // Update viewer count in Firestore
          if (isHost) {
            // _firestoreService.updateViewerCount(widget.streamId, _viewerCount);
          }
        },
        onRemoteVideoStateChanged:
            (
              RtcConnection connection,
              int remoteUid,
              RemoteVideoState state,
              RemoteVideoStateReason reason,
              int elapsed,
            ) {
              // Reduced logging for video state changes

              setState(() {
                if (state == RemoteVideoState.remoteVideoStateStarting ||
                    state == RemoteVideoState.remoteVideoStateDecoding) {
                  // User enabled video
                  if (!_videoCallerUids.contains(remoteUid) &&
                      remoteUid != _remoteUid) {
                    _videoCallerUids.add(remoteUid);
                  }
                } else if (state == RemoteVideoState.remoteVideoStateStopped) {
                  // User disabled video
                  _videoCallerUids.remove(remoteUid);

                  // Add to audio callers if they're still broadcasting audio
                  if (!_audioCallerUids.contains(remoteUid) &&
                      remoteUid != _remoteUid &&
                      _audioCallerUids.length < _maxAudioCallers) {
                    _audioCallerUids.add(remoteUid);
                  }
                }
              });
            },
        onRemoteAudioStateChanged:
            (
              RtcConnection connection,
              int remoteUid,
              RemoteAudioState state,
              RemoteAudioStateReason reason,
              int elapsed,
            ) {
              // Reduced logging for audio state changes

              // Track audio-only users (audio callers)
              if (state == RemoteAudioState.remoteAudioStateStarting ||
                  state == RemoteAudioState.remoteAudioStateDecoding) {
                setState(() {
                  // Add to audio callers if not already present and not the host
                  if (!_audioCallerUids.contains(remoteUid) &&
                      remoteUid != _remoteUid &&
                      _audioCallerUids.length < _maxAudioCallers) {
                    _audioCallerUids.add(remoteUid);
                  }
                });
              } else if (state == RemoteAudioState.remoteAudioStateStopped) {
                setState(() {
                  _audioCallerUids.remove(remoteUid);
                });
              }
            },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              _debugLog("User $remoteUid left channel");
              setState(() {
                // Remove from both audio and video callers if they were callers
                _audioCallerUids.remove(remoteUid);
                _videoCallerUids.remove(remoteUid);

                // Only set _remoteUid to null if it was the host who left
                if (_remoteUid == remoteUid) {
                  _remoteUid = null;
                }
                _remoteUsers.remove(remoteUid);
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
      // Apply saved camera preference immediately for preview
      await _applyCameraPreference();
      await _engine.startPreview();

      // Camera preference will be applied AFTER joining channel successfully
      // await _applyCameraPreference();
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('agora_token', result.token);
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

  /// Promote viewer to audio caller (join audio call)
  Future<void> _promoteToAudioCaller() async {
    if (_isAudioCaller) {
      _showSnackBar('🎤 You are already an audio caller', Colors.orange);
      return;
    }

    if (_audioCallerUids.length >= _maxAudioCallers) {
      _showSnackBar('🎤 Audio call is full ($_maxAudioCallers/3)', Colors.red);
      return;
    }

    if (_isJoiningAsAudioCaller) {
      _showSnackBar('🎤 Please wait, joining audio call...', Colors.blue);
      return;
    }

    try {
      setState(() {
        _isJoiningAsAudioCaller = true;
      });

      _showSnackBar('🎤 Joining audio call...', Colors.blue);

      // DON'T leave channel - just change role and settings
      // This prevents video freezing for the user
      await _switchToAudioCaller();

      setState(() {
        _isAudioCaller = true;
        _muted = false; // Enable microphone for audio caller
        _isJoiningAsAudioCaller = false;
      });

      _showSnackBar('🎤 Joined as audio caller!', Colors.green);
      debugPrint("Successfully promoted to audio caller");
    } catch (e) {
      debugPrint('❌ Error promoting to audio caller: $e');
      _showSnackBar('❌ Failed to join audio call', Colors.red);
      setState(() {
        _isJoiningAsAudioCaller = false;
      });
    }
  }

  /// Leave audio caller role and return to audience
  Future<void> _leaveAudioCaller() async {
    if (!_isAudioCaller) {
      return;
    }

    try {
      _showSnackBar('🎤 Leaving audio call...', Colors.blue);

      // DON'T leave channel - just change role and settings
      // This prevents video freezing for the user
      await _switchToAudience();

      setState(() {
        _isAudioCaller = false;
        _muted = true; // Mute as audience
      });

      _showSnackBar('👥 Returned to audience', Colors.green);
      debugPrint("Successfully left audio caller role");
    } catch (e) {
      debugPrint('❌ Error leaving audio caller: $e');
      _showSnackBar('❌ Failed to leave audio call', Colors.red);
    }
  }

  /// Check if user can become audio caller
  bool _canJoinAudioCall() {
    return !isHost &&
        !_isAudioCaller &&
        _audioCallerUids.length < _maxAudioCallers &&
        !_isJoiningAsAudioCaller;
  }

  /// Get audio caller count text
  String _getAudioCallerText() {
    return 'Join';
  }

  /// Switch Camera
  // ignore: unused_element
  Future<void> _turnOnOffCamera() async {
    try {
      if (_isInitializingCamera) {
        debugPrint('Camera is still initializing, please wait...');
        return;
      }

      if (!_isAudioCaller) {
        _showSnackBar(
          '🎤 Only audio callers can control camera',
          Colors.orange,
        );
        return;
      }

      // Toggle camera state
      setState(() {
        isCameraEnabled = !isCameraEnabled;
      });

      await _engine.enableLocalVideo(isCameraEnabled);
      await _engine.muteLocalVideoStream(!isCameraEnabled);

      if (isCameraEnabled) {
        debugPrint('📷 Camera turned on');
        _showSnackBar(
          '📷 Camera turned on - You are now visible!',
          Colors.green,
        );
      } else {
        debugPrint('📷 Camera turned off');
        _showSnackBar('📷 Camera turned off - Audio only mode', Colors.orange);
      }
    } catch (e) {
      debugPrint('❌ Error toggling camera: $e');
      _showSnackBar('❌ Failed to toggle camera', Colors.red);
      // Revert state on error
      setState(() {
        isCameraEnabled = !isCameraEnabled;
      });
    }
  }

  /// Optimized role switching without channel interruption
  Future<void> _switchToAudioCaller() async {
    try {
      // Set role to broadcaster to enable audio publishing
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Configure media settings for audio caller
      await _engine.enableLocalAudio(true); // Enable audio publishing
      await _engine.enableLocalVideo(false); // Start with video disabled
      await _engine.muteLocalVideoStream(
        true,
      ); // Ensure video is muted initially
      await _engine.muteLocalAudioStream(false); // Unmute microphone

      // Reset camera state to false for audio callers
      setState(() {
        isCameraEnabled = false;
      });

      debugPrint(
        "✅ Switched to audio caller role without channel interruption",
      );
    } catch (e) {
      debugPrint("❌ Error switching to audio caller: $e");
      rethrow;
    }
  }

  /// Optimized role switching back to audience
  Future<void> _switchToAudience() async {
    try {
      // Set role back to audience
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);

      // Configure media settings for audience
      await _engine.enableLocalAudio(false); // Disable audio publishing
      await _engine.enableLocalVideo(false); // Keep video disabled for audience
      await _engine.muteLocalAudioStream(true); // Mute microphone

      // Reset camera state
      setState(() {
        isCameraEnabled = false;
      });

      debugPrint(
        "✅ Switched back to audience role without channel interruption",
      );
    } catch (e) {
      debugPrint("❌ Error switching to audience: $e");
      rethrow;
    }
  }

  // Toggle microphone
  void _toggleMute() async {
    if (isHost || _isAudioCaller) {
      // Check if user is trying to unmute but is administratively muted
      if (_muted && _isCurrentUserMuted()) {
        _showSnackBar(
          '🔇 You cannot unmute yourself - you have been muted by an admin',
          Colors.red,
        );
        return;
      }

      await _engine.muteLocalAudioStream(!_muted);
      setState(() {
        _muted = !_muted;
      });

      if (_muted) {
        _showSnackBar('🔇 Microphone muted', Colors.orange);
      } else {
        _showSnackBar('🎤 Microphone unmuted', Colors.green);
      }
    } else {
      _showSnackBar(
        '🎤 Only hosts and audio callers can use microphone',
        Colors.orange,
      );
    }
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

  // Play animation for two seconds
  void _playAnimation() {
    setState(() {
      _animationPlaying = true;
    });

    // Stop the animation after 2 seconds
    Future.delayed(const Duration(seconds: 7), () {
      setState(() {
        _animationPlaying = false;
      });
    });
  }

  // End live stream
  void _endLiveStream() async {
    try {
      // Stop the stream timer
      _stopStreamTimer();

      // Reset audio caller state
      setState(() {
        _isAudioCaller = false;
        _audioCallerUids.clear();
        _videoCallerUids.clear();
        _isJoiningAsAudioCaller = false;
        isCameraEnabled = false;
      });

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

                  if (_animationPlaying) AnimatedLayer(gifts: sentGifts),

                  // * This contaimer holds the livestream options,
                  SafeArea(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 30.h,
                      ),
                      child: Column(
                        spacing: 15.h,
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
                                  hostUserId: state.user.id,
                                  currentUserId: state.user.id,
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
                                  hostUserId: widget.hostUserId ?? "",
                                  currentUserId: state.user.id,
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
                                        height: 50.h,
                                        // width: 40.w,
                                      ),
                                    )
                                  : InkWell(
                                      onTap: () {
                                        _endLiveStream();
                                        debugPrint("Disconnect pressed");
                                      },
                                      child: Image.asset(
                                        "assets/icons/live_exit_icon.png",
                                        height: 50.h,
                                      ),
                                    ),
                            ],
                          ),

                          //  this is the second row TODO:  diamond and star count display
                          DiamondStarStatus(
                            diamonCount: AppUtils.formatNumber(
                              GiftModel.totalDiamonds(sentGifts),
                            ),
                            starCount: AppUtils.formatNumber(0),
                          ),

                          Spacer(),

                          // Chat widget - positioned at bottom left
                          Align(
                            alignment: Alignment.centerLeft,
                            child: LiveChatWidget(messages: _chatMessages),
                          ),

                          SizedBox(height: 10.h),

                          // the bottom buttons
                          if (isHost)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () {
                                    showSendMessageBottomSheet(
                                      context,
                                      onSendMessage: (message) {
                                        print("Send message pressed");
                                        _emitMessageToSocket(message);
                                      },
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Image.asset(
                                        "assets/icons/message_icon.png",
                                        height: 40.h,
                                      ),
                                      Positioned(
                                        left: 10.w,
                                        top: 0,
                                        bottom: 0,
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              "assets/icons/message_user_icon.png",
                                              height: 20.h,
                                            ),
                                            SizedBox(width: 5.w),
                                            Text(
                                              'Say Hello!',
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
                                  onTap: () {
                                    // _showSnackBar(
                                    //   '🎁 Not implemented yet',
                                    //   Colors.green,
                                    // );
                                    showGiftBottomSheet(
                                      context,
                                      activeViewers: activeViewers,
                                      roomId: _currentRoomId ?? roomId,
                                      hostUserId: isHost
                                          ? userId
                                          : widget.hostUserId,
                                      hostName: isHost
                                          ? state.user.name
                                          : widget.hostName,
                                      hostAvatar: isHost
                                          ? state.user.avatar
                                          : widget.hostAvatar,
                                    );
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/pk_icon.png",
                                  onTap: () {
                                    _playAnimation();
                                    _showSnackBar(
                                      '🎶 Not implemented yet',
                                      Colors.green,
                                    );
                                    // showMusicBottomSheet(context);
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: _muted
                                      ? "assets/icons/mute_icon.png"
                                      : "assets/icons/unmute_icon.png",
                                  onTap: () {
                                    _toggleMute();
                                  },
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/call_icon.png",
                                  onTap: () {
                                    if (_audioCallerUids.isNotEmpty) {
                                      _showSnackBar(
                                        '🎤 ${_audioCallerUids.length} audio caller${_audioCallerUids.length > 1 ? 's' : ''} connected',
                                        Colors.green,
                                      );
                                    } else {
                                      _showSnackBar(
                                        '📞 Waiting for audio callers to join...',
                                        Colors.blue,
                                      );
                                    }
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => CallManageBottomSheet(
                                        key: callManageBottomSheetKey,
                                        onAcceptCall: (userId) {
                                          debugPrint(
                                            "Accepting call request from $userId",
                                          );
                                          _socketService.acceptCallRequest(
                                            userId,
                                          );
                                          callRequests.removeWhere(
                                            (call) => call.userId == userId,
                                          );
                                          // Update the bottom sheet with new data
                                          _updateCallManageBottomSheet();
                                        },
                                        onRejectCall: (userId) {
                                          debugPrint(
                                            "Rejecting call request from $userId",
                                          );
                                          _socketService.rejectCallRequest(
                                            userId,
                                          );
                                          // Update the bottom sheet with new data
                                          _updateCallManageBottomSheet();
                                        },
                                        onKickUser: (userId) {
                                          _socketService.removeBroadcaster(
                                            userId,
                                          );
                                          debugPrint(
                                            "Kicking user $userId from call",
                                          );
                                          // Update the bottom sheet with new data
                                          _updateCallManageBottomSheet();
                                        },
                                        callers: callRequests,
                                        inCallList: broadcasterModels,
                                      ),
                                    );
                                  },
                                ),

                                CustomLiveButton(
                                  iconPath: "assets/icons/menu_icon.png",
                                  onTap: () {
                                    showGameBottomSheet(
                                      context,
                                      userId: userId,
                                      isHost: isHost,
                                      streamDuration: _streamDuration,
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
                                    // _showSnackBar(
                                    //   '💬 Not implemented yet',
                                    //   Colors.green,
                                    // );
                                    showSendMessageBottomSheet(
                                      context,
                                      onSendMessage: (message) {
                                        print("Send message pressed");
                                        _emitMessageToSocket(message);
                                      },
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Image.asset(
                                        "assets/icons/message_icon.png",
                                        height: 40.h,
                                      ),
                                      Positioned(
                                        left: 10,
                                        top: 0,
                                        bottom: 0,
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              "assets/icons/message_user_icon.png",
                                              height: 20.h,
                                            ),
                                            SizedBox(width: 5.w),
                                            Text(
                                              'Say Hello!',
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
                                  onTap: () {
                                    showGiftBottomSheet(
                                      context,
                                      activeViewers: activeViewers,
                                      roomId: _currentRoomId ?? roomId,
                                      hostUserId: isHost
                                          ? userId
                                          : widget.hostUserId,
                                      hostName: isHost
                                          ? state.user.name
                                          : widget.hostName,
                                      hostAvatar: isHost
                                          ? state.user.avatar
                                          : widget.hostAvatar,
                                    );
                                  },
                                  height: 40.h,
                                ),

                                CustomLiveButton(
                                  iconPath: "assets/icons/game_user_icon.png",
                                  onTap: () {
                                    showGameBottomSheet(
                                      context,
                                      userId: userId,
                                      streamDuration: _streamDuration,
                                    );
                                  },
                                  height: 40.h,
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/share_user_icon.png",
                                  onTap: () {},
                                  height: 40.h,
                                ),
                                CustomLiveButton(
                                  iconPath: "assets/icons/menu_icon.png",
                                  onTap: () {
                                    showMenuBottomSheet(
                                      context,
                                      userId: userId,
                                      isHost: isHost,
                                      isMuted: _muted,
                                      isAdminMuted: _isCurrentUserMuted(),
                                      onToggleMute: _toggleMute,
                                    );
                                  },
                                  height: 40.h,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (!isHost)
                    Positioned(
                      bottom: 140.h,
                      right: 30.w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Caller Widget
                          ...broadcasterModels.map((broadcaster) {
                            // Check if broadcaster is the current user
                            WhoAmI checkRole(String broadcasterId) {
                              // Get current user ID from AuthBloc for reliability
                              final authState = context.read<AuthBloc>().state;
                              final currentUserId =
                                  authState is AuthAuthenticated
                                  ? authState.user.id
                                  : userId;

                              if (_isCurrentUserAdmin()) {
                                return WhoAmI.admin;
                              } else if (_isCurrentUserHost()) {
                                return WhoAmI.host;
                              } else if (broadcaster.id == currentUserId) {
                                return WhoAmI.myself;
                              } else {
                                return WhoAmI.user;
                              }
                            }

                            return CallOverlayWidget(
                              whoAmI: checkRole(broadcaster.id),
                              userId: broadcaster.id,
                              userName: broadcaster.name,
                              userImage: broadcaster.avatar.isNotEmpty
                                  ? broadcaster.avatar
                                  : null, // null will show placeholder
                              onDisconnect: () {
                                _socketService.removeBroadcaster(
                                  broadcaster.id,
                                );
                              },
                              onMute: () {
                                _muteUser(broadcaster.id);
                              },
                              onManage: () {
                                // No-op here; bottom sheet handles actions
                                debugPrint(
                                  "Open manage for: ${broadcaster.id}",
                                );
                              },
                              onSetAdmin: (id) {
                                _makeAdmin(id);
                                _showSnackBar('👑 Set as admin', Colors.green);
                              },
                              onRemoveAdmin: (id) {
                                _removeAdmin(id);
                                _showSnackBar(
                                  '👤 Admin removed',
                                  Colors.orange,
                                );
                              },
                              adminModels: adminModels,
                              onMuteUser: (id) {
                                _muteUser(id);
                                _showSnackBar('🔇 User muted', Colors.orange);
                              },
                              onKickOut: (id) {
                                _banUser(id);
                                _showSnackBar('👢 User kicked out', Colors.red);
                              },
                              onBanUser: (id) {
                                _banUser(id);
                                _showSnackBar(
                                  '⛔ User added to blocklist',
                                  Colors.red,
                                );
                              },
                            );
                          }),
                          SizedBox(height: 80.h),
                          // Audio caller status indicator
                          if (broadcasterList.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              child: Text(
                                '🎤 ${broadcasterList.length}/$_maxAudioCallers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          // Camera toggle button
                          // if (_isAudioCaller)
                          //   GestureDetector(
                          //     onTap: () {
                          //       _turnOnOffCamera();
                          //       debugPrint("Camera toggled");
                          //     },
                          //     child: Container(
                          //       height: 40.h,
                          //       width: 40.w,
                          //       alignment: Alignment.center,
                          //       decoration: BoxDecoration(
                          //         borderRadius: BorderRadius.all(
                          //           Radius.circular(8.r),
                          //         ),
                          //         color: isCameraEnabled
                          //             ? Colors.orange
                          //             : Colors.grey,
                          //       ),
                          //       child: Icon(
                          //         isCameraEnabled
                          //             ? Icons.videocam
                          //             : Icons.videocam_off,
                          //         color: Colors.white,
                          //         size: 24.sp,
                          //       ),
                          //     ),
                          //   ),
                          // SizedBox(height: 10.h),
                          // Main call button
                          GestureDetector(
                            onTap: () {
                              if (_isJoiningAsAudioCaller) {
                                _showSnackBar(
                                  '🎤 Please wait...',
                                  Colors.orange,
                                );
                                return;
                              }

                              if (_isAudioCaller) {
                                _socketService.removeBroadcaster(userId ?? '');
                                debugPrint("Leaving audio caller");
                              } else {
                                _socketService.joinCallRequest(
                                  _currentRoomId ?? roomId,
                                );
                                _showSnackBar(
                                  '🎤 Please wait for accept call...',
                                  Colors.orange,
                                );
                                debugPrint("Join call request sent");
                              }
                            },
                            child: Container(
                              height: 80.h,
                              width: 80.w,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.r),
                                ),
                                color: _isJoiningAsAudioCaller
                                    ? Colors.grey
                                    : _isAudioCaller
                                    ? Colors.orange
                                    : _canJoinAudioCall()
                                    ? Color(0xFFFEB86F)
                                    : Color(0xFFFEB86F),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  _isJoiningAsAudioCaller
                                      ? SizedBox(
                                          width: 40.w,
                                          height: 40.h,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : _isAudioCaller
                                      ? SvgPicture.asset(
                                          "assets/icons/join_call_icon.svg",
                                          height: 40.h,
                                          width: 40.w,
                                        )
                                      : SvgPicture.asset(
                                          "assets/icons/join_call_icon.svg",
                                          height: 40.h,
                                          width: 40.w,
                                        ),
                                  Text(
                                    _isJoiningAsAudioCaller
                                        ? 'Joining'
                                        : _isAudioCaller
                                        ? 'Leave'
                                        : _canJoinAudioCall()
                                        ? _getAudioCallerText()
                                        : 'Call Full',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Positioned(
                      bottom: 140.h,
                      right: 30.w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Caller Widget
                          ...broadcasterModels.map((broadcaster) {
                            // Check if broadcaster is the current user (for host section)
                            WhoAmI checkHostRole(String broadcasterId) {
                              // Get current user ID from AuthBloc for reliability
                              final authState = context.read<AuthBloc>().state;
                              final currentUserId =
                                  authState is AuthAuthenticated
                                  ? authState.user.id
                                  : userId;

                              if (_isCurrentUserAdmin()) {
                                return WhoAmI.admin;
                              } else if (_isCurrentUserHost()) {
                                return WhoAmI.host;
                              } else if (broadcaster.id == currentUserId) {
                                return WhoAmI.myself;
                              } else {
                                return WhoAmI.user;
                              }
                            }

                            return CallOverlayWidget(
                              whoAmI: checkHostRole(broadcaster.id),
                              userId: broadcaster.id,
                              userName: broadcaster.name,
                              userImage: broadcaster.avatar.isNotEmpty
                                  ? broadcaster.avatar
                                  : null, // null will show placeholder
                              onDisconnect: () {
                                _socketService.removeBroadcaster(
                                  broadcaster.id,
                                );
                              },
                              onMute: () {
                                _muteUser(broadcaster.id);
                              },
                              onManage: () {
                                // No-op; actions are fired from bottom sheet
                                debugPrint(
                                  "Open manage for: ${broadcaster.id}",
                                );
                              },
                              onSetAdmin: (id) {
                                _makeAdmin(id);
                                _showSnackBar('👑 Set as admin', Colors.green);
                              },
                              onRemoveAdmin: (id) {
                                _removeAdmin(id);
                                _showSnackBar(
                                  '👤 Admin removed',
                                  Colors.orange,
                                );
                              },
                              adminModels: adminModels,
                              onMuteUser: (id) {
                                _muteUser(id);
                                _showSnackBar('🔇 User muted', Colors.orange);
                              },
                              onKickOut: (id) {
                                _banUser(id);
                                _showSnackBar('👢 User kicked out', Colors.red);
                              },
                              onBanUser: (id) {
                                _banUser(id);
                                _showSnackBar(
                                  '⛔ User added to blocklist',
                                  Colors.red,
                                );
                              },
                            );
                          }),
                          SizedBox(height: 180.h),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Main video view with multi-broadcaster support
  Widget _buildVideoView() {
    // Removed spammy debug print that was called on every rebuild

    // Show loading indicator during camera initialization
    if (_isInitializingCamera) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              // SizedBox(height: 20.h),
              // Text(
              //   '🎥 Initializing camera...',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 18.sp,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              // SizedBox(height: 10.h),
              // Text(
              //   'Please wait while we set up your stream',
              //   style: TextStyle(color: Colors.grey, fontSize: 14),
              // ),
            ],
          ),
        ),
      );
    }

    if (isHost) {
      // Host view with multi-broadcaster layout
      return _buildHostMultiView();
    } else {
      // Audience view with multi-broadcaster layout
      return _buildAudienceMultiView();
    }
  }

  /// Build multi-broadcaster view for host
  Widget _buildHostMultiView() {
    // Get all video broadcasters (video callers)
    List<int> allVideoBroadcasters = [
      if (_localUserJoined) 0, // Host's own video (UID 0)
      ..._videoCallerUids, // Video callers
    ];

    if (allVideoBroadcasters.isEmpty || !_localUserJoined) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              // SizedBox(height: 20.h),
              // Text(
              //   '📡 Connecting to stream...',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 18.sp,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
            ],
          ),
        ),
      );
    }

    return _buildMultiVideoLayout(allVideoBroadcasters, isHostView: true);
  }

  /// Build multi-broadcaster view for audience
  Widget _buildAudienceMultiView() {
    // Get all video broadcasters
    List<int> allVideoBroadcasters = [
      if (_remoteUid != null) _remoteUid!, // Host video
      ..._videoCallerUids, // Video callers
      if (_isAudioCaller && isCameraEnabled)
        0, // Own video if audio caller with camera on
    ];

    if (allVideoBroadcasters.isEmpty) {
      // Start host disconnection monitoring when no video broadcasters are present
      if (!isHost) {
        _startHostDisconnectionMonitoring();
      }

      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              // SizedBox(height: 20.h),
              // Text(
              //   'Host is disconnected',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 18.sp,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              // SizedBox(height: 10.h),
              // Text(
              //   'Please wait...',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(color: Colors.grey, fontSize: 14),
              // ),
            ],
          ),
        ),
      );
    } else {
      // Cancel host disconnection monitoring if video broadcasters are present
      if (_hostActivityTimer != null) {
        _hostActivityTimer?.cancel();
        _hostActivityTimer = null;
      }
    }

    return _buildMultiVideoLayout(allVideoBroadcasters, isHostView: false);
  }

  /// Build dynamic multi-video layout based on number of broadcasters
  Widget _buildMultiVideoLayout(
    List<int> broadcasterUids, {
    required bool isHostView,
  }) {
    int broadcasterCount = broadcasterUids.length;

    // Removed spammy debug print that was called on every rebuild

    if (broadcasterCount == 1) {
      // Single broadcaster - full screen
      return _buildSingleVideoView(broadcasterUids[0], isHostView: isHostView);
    } else if (broadcasterCount == 2) {
      // Two broadcasters - split screen
      return _buildTwoBroadcasterLayout(
        broadcasterUids,
        isHostView: isHostView,
      );
    } else if (broadcasterCount == 3) {
      // Three broadcasters - main + 2 small
      return _buildThreeBroadcasterLayout(
        broadcasterUids,
        isHostView: isHostView,
      );
    } else if (broadcasterCount >= 4) {
      // Four or more broadcasters - grid layout
      return _buildFourBroadcasterLayout(
        broadcasterUids,
        isHostView: isHostView,
      );
    }

    return Container(color: Colors.black); // Fallback
  }

  /// Single broadcaster view
  Widget _buildSingleVideoView(int uid, {required bool isHostView}) {
    if (uid == 0) {
      // Local video (host or audio caller with camera)
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      // Remote video
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: roomId),
        ),
      );
    }
  }

  /// Two broadcaster layout - split screen
  Widget _buildTwoBroadcasterLayout(
    List<int> uids, {
    required bool isHostView,
  }) {
    return Column(
      children: [
        Expanded(child: _buildSingleVideoView(uids[0], isHostView: isHostView)),
        Container(height: 2.h, color: Colors.white24), // Separator
        Expanded(child: _buildSingleVideoView(uids[1], isHostView: isHostView)),
      ],
    );
  }

  /// Three broadcaster layout - main view + 2 small views
  Widget _buildThreeBroadcasterLayout(
    List<int> uids, {
    required bool isHostView,
  }) {
    return Stack(
      children: [
        // Main video (first broadcaster - usually host)
        _buildSingleVideoView(uids[0], isHostView: isHostView),

        // Small video views on the right
        Positioned(
          top: 100.h,
          right: 10.w,
          child: Column(
            children: [
              Container(
                width: 120.w,
                height: 160.h,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2.w),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: _buildSingleVideoView(uids[1], isHostView: isHostView),
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                width: 120.w,
                height: 160.h,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2.w),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: _buildSingleVideoView(uids[2], isHostView: isHostView),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Four+ broadcaster layout - 2x2 grid
  Widget _buildFourBroadcasterLayout(
    List<int> uids, {
    required bool isHostView,
  }) {
    // Take first 4 broadcasters for grid layout
    List<int> gridUids = uids.take(4).toList();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildSingleVideoView(
                  gridUids[0],
                  isHostView: isHostView,
                ),
              ),
              Container(
                width: 2.w,
                color: Colors.white24,
              ), // Vertical separator
              Expanded(
                child: _buildSingleVideoView(
                  gridUids[1],
                  isHostView: isHostView,
                ),
              ),
            ],
          ),
        ),
        Container(height: 2.h, color: Colors.white24), // Horizontal separator
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildSingleVideoView(
                  gridUids[2],
                  isHostView: isHostView,
                ),
              ),
              Container(
                width: 2.w,
                color: Colors.white24,
              ), // Vertical separator
              Expanded(
                child: _buildSingleVideoView(
                  gridUids.length > 3 ? gridUids[3] : gridUids[0],
                  isHostView: isHostView,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

    // Stop host activity timer
    _hostActivityTimer?.cancel();

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
