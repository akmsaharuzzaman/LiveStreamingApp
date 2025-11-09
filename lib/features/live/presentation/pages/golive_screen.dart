import 'dart:async';
// import 'dart:math'; // removed unused import
import 'package:flutter/foundation.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/broadcaster_model.dart';
import 'package:dlstarlive/core/network/models/call_request_model.dart';
import 'package:dlstarlive/core/network/models/chat_model.dart';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/socket_service.dart';
import 'package:dlstarlive/core/utils/permission_helper.dart';
import 'package:dlstarlive/features/live/presentation/bloc/bloc.dart';
import 'package:dlstarlive/features/live/presentation/component/agora_token_service.dart';
import 'package:dlstarlive/features/live/presentation/component/gift_bottom_sheet.dart';
import 'package:dlstarlive/features/live/presentation/component/send_message_buttonsheet.dart';
import 'package:dlstarlive/features/live/presentation/widgets/call_overlay_widget.dart';
import 'package:dlstarlive/injection/injection.dart';
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

class GoliveScreen extends StatelessWidget {
  final String? roomId;
  final String? hostName;
  final String? hostUserId;
  final String? hostAvatar;
  final List<HostDetails> existingViewers;
  final int hostCoins;
  final GetRoomModel? roomData; // Add room data to load initial state

  const GoliveScreen({
    super.key,
    this.roomId,
    this.hostName,
    this.hostUserId,
    this.hostAvatar,
    this.existingViewers = const [],
    this.hostCoins = 0,
    this.roomData, // Optional room data for existing rooms
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LiveStreamBloc>(
          create: (context) => getIt<LiveStreamBloc>()
            ..add(InitializeLiveStream(
              roomId: roomId,
              hostUserId: hostUserId,
              isHost: roomId == null, // If no roomId passed, we are creating (host)
            )),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => getIt<ChatBloc>()..add(const LoadInitialMessages([])),
        ),
        BlocProvider<GiftBloc>(
          create: (context) => getIt<GiftBloc>()..add(const LoadInitialGifts([])),
        ),
        BlocProvider<CallRequestBloc>(
          create: (context) => getIt<CallRequestBloc>()..add(const LoadInitialBroadcasters([])),
        ),
      ],
      child: _GoliveScreenContent(
        roomId: roomId,
        hostName: hostName,
        hostUserId: hostUserId,
        hostAvatar: hostAvatar,
        existingViewers: existingViewers,
        hostCoins: hostCoins,
        roomData: roomData,
      ),
    );
  }
}

class _GoliveScreenContent extends StatefulWidget {
  final String? roomId;
  final String? hostName;
  final String? hostUserId;
  final String? hostAvatar;
  final List<HostDetails> existingViewers;
  final int hostCoins;
  final GetRoomModel? roomData;

  const _GoliveScreenContent({
    this.roomId,
    this.hostName,
    this.hostUserId,
    this.hostAvatar,
    this.existingViewers = const [],
    this.hostCoins = 0,
    this.roomData,
  });

  @override
  State<_GoliveScreenContent> createState() => _GoliveScreenContentState();
}

class _GoliveScreenContentState extends State<_GoliveScreenContent> {
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
  final Set<String> _knownPendingRequestIds = {};
  final Set<String> _knownBroadcasterIds = {};
  // Banned users
  List<String> bannedUsers = [];
  // Banned user details
  List<BanUserModel> bannedUserModels = [];
  // Mute user details - store only the latest mute state
  MuteUserModel? currentMuteState;
  //Admin Details
  List<AdminDetailsModel> adminModels = [];

  // ✅ Live stream timing - Now managed by LiveStreamBloc
  // Keeping local copy for backward compatibility with existing code
  // TODO: Remove after full migration
  Duration _streamDuration = Duration.zero;

  // Daily bonus tracking - ✅ Now handled by LiveStreamBloc state
  // Kept for backward compatibility only
  int _lastBonusMilestone = 0;

  // Configurable interval for bonus API calls (in minutes) - for debugging
  // Set to 1 for testing, 50 for production
  static const int _bonusIntervalMinutes = 50;

  //Live inactivity timeout duration
  static const int _inactivityTimeoutSeconds = 60;

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

  // Additional socket stream subscriptions
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _sentMessageSubscription;
  StreamSubscription? _sentGiftSubscription;
  StreamSubscription? _bannedListSubscription;
  StreamSubscription? _bannedUserSubscription;

  // Chat messages
  final List<ChatModel> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _resetState(); // ✅ Reset all state before initializing
    _initializeFromRoomData(); // Initialize from existing room data
    _initializeExistingViewers();
    extractRoomId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndDispatchEvent();
    });
  }

  /// ✅ Reset all state variables to clean slate
  void _resetState() {
    debugPrint("🔄 Resetting screen state...");
    activeViewers.clear();
    _knownPendingRequestIds.clear();
    _knownBroadcasterIds.clear();
    bannedUsers.clear();
    bannedUserModels.clear();
    currentMuteState = null;
    adminModels.clear();
    _chatMessages.clear();
    // ✅ Duration now managed by LiveStreamBloc
    _streamDuration = Duration.zero;
    _lastBonusMilestone = 0;
    _lastHostActivity = null;
    _animationPlaying = false;
    _currentRoomId = null;
    userId = null;
    isHost = true;
    roomId = "default_channel";
    debugPrint("✅ State reset complete");
  }

  /// Initialize state from existing room data (when joining existing live)
  void _initializeFromRoomData() {
    if (widget.roomData != null) {
      final roomData = widget.roomData!;

      // ✅ Duration now managed by LiveStreamBloc
      // Initialize from existing duration
      if (roomData.duration > 0) {
        _streamDuration = Duration(seconds: roomData.duration);
        debugPrint(
          "🕒 Initialized stream with existing duration: ${roomData.duration}s",
        );
      }

      // ✅ Bonus data now in LiveStreamBloc state
      // roomData.hostBonus will be synced via BLoC initialization

      // Calculate last milestone based on existing duration to prevent duplicate API calls
      if (roomData.duration > 0) {
        int existingMinutes = (roomData.duration / 60).floor();
        _lastBonusMilestone =
            (existingMinutes ~/ _bonusIntervalMinutes) * _bonusIntervalMinutes;
        debugPrint(
          "🎯 Set last milestone to: $_lastBonusMilestone minutes based on duration: $existingMinutes minutes",
        );
      }

      debugPrint(
        "💰 Initialized with existing bonus: ${roomData.hostBonus} diamonds",
      );

      // Initialize chat messages if any

      if (roomData.messages.isNotEmpty) {
        _chatMessages.clear();
        for (var messageData in roomData.messages) {
          if (messageData is Map<String, dynamic>) {
            try {
              final chatMessage = ChatModel.fromJson(messageData);
              _chatMessages.add(chatMessage);
            } catch (e) {
              debugPrint("❌ Error parsing message: $e");
              debugPrint("❌ Message data: $messageData");
            }
          }
        }
        debugPrint("💬 Loaded ${_chatMessages.length} existing messages");
        context
            .read<ChatBloc>()
            .add(LoadInitialMessages(List.from(_chatMessages)));
      }

      // Initialize broadcasters (excluding host)
      if (roomData.broadcastersDetails.isNotEmpty) {
        final initialBroadcasters = <BroadcasterModel>[];
        for (var broadcaster in roomData.broadcastersDetails) {
          // Don't add host to broadcaster list
          if (broadcaster.id != roomData.hostId) {
            initialBroadcasters.add(
              BroadcasterModel(
                id: broadcaster.id,
                name: broadcaster.name,
                avatar: broadcaster.avatar,
                uid: broadcaster.uid,
              ),
            );
          }
        }
        if (initialBroadcasters.isNotEmpty) {
          context
              .read<CallRequestBloc>()
              .add(LoadInitialBroadcasters(initialBroadcasters));
          debugPrint(
            "🎤 Loaded ${initialBroadcasters.length} existing broadcasters (host excluded)",
          );
        }
      }

      // Initialize call requests
      if (roomData.callRequests.isNotEmpty) {
        final initialRequests = roomData.callRequests.map((request) {
          return CallRequestModel(
            userId: request.id,
            userDetails: UserDetails(
              id: request.id,
              avatar: request.avatar,
              name: request.name,
              uid: request.uid,
            ),
            roomId: roomData.roomId,
          );
        }).toList();

        context
            .read<CallRequestBloc>()
            .add(LoadCallRequestList(initialRequests));
        debugPrint(
          "📞 Loaded ${initialRequests.length} existing call requests",
        );
      }

      // Initialize members as active viewers (excluding host)
      if (roomData.membersDetails.isNotEmpty) {
        activeViewers.clear();
        for (var member in roomData.membersDetails) {
          // Don't add host to viewers list
          if (member.id != roomData.hostId) {
            final viewer = JoinedUserModel(
              id: member.id,
              avatar: member.avatar,
              name: member.name,
              uid: member.uid,
              currentLevel: member.currentLevel,
              currentBackground: member.currentBackground,
              currentTag: member.currentTag,
              diamonds: 0, // Initialize with 0, will be updated from gifts
            );
            activeViewers.add(viewer);
          }
        }
        debugPrint(
          "👥 Loaded ${activeViewers.length} existing members as viewers",
        );
      }

      // Set room ID if not already set
      if (_currentRoomId == null && roomData.roomId.isNotEmpty) {
        _currentRoomId = roomData.roomId;
        debugPrint("🏠 Set room ID from existing data: ${roomData.roomId}");
      }

      debugPrint("✅ Successfully initialized from existing room data");
    }
  }

  // ✅ REMOVED: _debugDiamondStatus() - Unused debug method (27 lines)
  // ✅ REMOVED: _updateUserDiamonds() - Unused method for updating local activeViewers diamonds (58 lines)
  // Both methods are now redundant - viewer data is managed by LiveStreamBloc

  /// Calculate total bonus diamonds earned from daily streaming bonuses (configurable intervals)
  // int _calculateTotalBonusDiamonds() {
  //   return _totalBonusDiamonds;
  // }

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
          currentLevel: hostDetail.currentLevel,
          currentBackground: hostDetail.currentBackground,
          currentTag: hostDetail.currentTag,
          diamonds:
              0, // Initialize with 0, will be updated when gifts are received
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

    // Note: Host coins initialization moved to _loadUidAndDispatchEvent after userId is set
  }

  /// Initialize host coins as synthetic gifts for display purposes
  void _initializeHostCoins() {
    if (widget.hostCoins > 0) {
      debugPrint("💰 Initializing host coins: ${widget.hostCoins}");

      // Create a synthetic gift model to represent existing host coins
      // Use widget.hostUserId (always available) or userId if this user is the host
      String? hostId = widget.hostUserId;

      // If we don't have hostUserId from widget, but this user is the host, use userId
      if (hostId == null && isHost && userId != null) {
        hostId = userId;
      }

      debugPrint(
        "🔍 Using host ID: $hostId (isHost: $isHost, userId: $userId, widget.hostUserId: ${widget.hostUserId})",
      );

      if (hostId != null && hostId.isNotEmpty) {
        GiftModel syntheticGift = GiftModel(
          avatar: widget.hostAvatar ?? "https://thispersondoesnotexist.com/",
          name: widget.hostName ?? "Host",
          recieverIds: [hostId],
          diamonds: widget.hostCoins,
          qty: 1,
          gift: Gift(
            id: "synthetic_initial_coins",
            name: "Initial Coins",
            category: "System",
            diamonds: widget.hostCoins,
            coinPrice: widget.hostCoins,
            previewImage: "",
            svgaImage: "",
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            v: 0,
          ),
        );

        context.read<GiftBloc>().add(LoadInitialGifts([syntheticGift]));
        debugPrint(
          "✅ Added synthetic gift for host coins: ${widget.hostCoins} to host ID: $hostId",
        );
      } else {
        debugPrint(
          "⚠️ Could not initialize host coins - host ID is null or empty",
        );
        debugPrint("   widget.hostUserId: ${widget.hostUserId}");
        debugPrint("   userId: $userId");
        debugPrint("   isHost: $isHost");
      }
    } else {
      debugPrint("💰 No host coins to initialize (${widget.hostCoins})");
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

      // Initialize host coins after userId is set
      if (widget.hostCoins > 0) {
        _initializeHostCoins();
      }

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

    // ✅ User join/leave events now handled by LiveStreamBloc
    // No need for duplicate socket subscriptions here
    // _userJoinedSubscription and _userLeftSubscription removed

    // ✅ Sent Messages - Now handled by ChatBloc
    // _sentMessageSubscription = _socketService.sentMessageStream.listen((data) {
    //   if (mounted) {
    //     debugPrint("User sent a message: ${data.text}");
    //     setState(() {
    //       _chatMessages.add(data);
    //       if (_chatMessages.length > 50) {
    //         _chatMessages.removeAt(0);
    //       }
    //     });
    //   }
    // });

    // ✅ User left - Now handled by LiveStreamBloc
    // activeViewers management moved to BLoC state
    _userLeftSubscription = _socketService.userLeftStream.listen((data) {
      if (mounted) {
        // ✅ No need to update activeViewers or broadcasters - handled by BLoCs
        debugPrint("User left: ${data.name} - ${data.id}");
      }
    });

    // ✅ Sent Gifts - Now handled by GiftBloc
    // _sentGiftSubscription = _socketService.sentGiftStream.listen((data) {
    //   if (mounted) {
    //     debugPrint("🎁 Gift received from socket: ${data.gift.name}");
    //     debugPrint("💰 Gift diamonds: ${data.diamonds}");
    //     debugPrint("🎯 Receivers: ${data.recieverIds}");
    //     debugPrint("🔍 Is current user host? $isHost");
    //     debugPrint("🔍 Current user ID: $userId");
    //     debugPrint("🔍 Host user ID: ${widget.hostUserId}");
    //
    //     setState(() {
    //       sentGifts.add(data);
    //       // Update diamonds for users who received the gift
    //       _updateUserDiamonds(data);
    //     });
    //
    //     debugPrint("📊 Total gifts in list: ${sentGifts.length}");
    //
    //     // Calculate host diamonds separately for verification
    //     int hostDiamonds = GiftModel.totalDiamondsForHost(
    //       sentGifts,
    //       widget.hostUserId,
    //     );
    //     debugPrint("🏆 Host total diamonds (calculated): $hostDiamonds");
    //
    //     // For host, also check using current userId
    //     if (isHost && userId != null) {
    //       int hostDiamondsFromUserId = GiftModel.totalDiamondsForUser(
    //         sentGifts,
    //         userId!,
    //       );
    //       debugPrint("🏆 Host diamonds using userId: $hostDiamondsFromUserId");
    //     }
    //
    //     // Debug current status
    //     _debugDiamondStatus();
    //
    //     // Force UI update
    //     if (mounted) {
    //       setState(() {
    //         // Trigger rebuild to ensure DiamondStarStatus updates
    //       });
    //     }
    //
    //     sentGifts.isNotEmpty ? _playAnimation() : null;
    //   }
    // });

    //BannedUserList
    _bannedListSubscription = _socketService.bannedListStream.listen((data) {
      if (mounted) {
        setState(() {
          bannedUsers = List.from(data);
        });
        debugPrint("Banned user list updated: $bannedUsers");
        if (bannedUsers.contains(userId)) {
          _handleHostDisconnection("You have been banned from this room.");
        }
      }
    });

    // ✅ BannedUsers - Now handled by LiveStreamBloc via UserBannedNotification event
    // Socket listener moved to BLoC, just keep UI-specific logic here
    _bannedUserSubscription = _socketService.bannedUserStream.listen((data) {
      debugPrint("Banned user received:${data.targetId}");
      if (mounted) {
        // Keep only UI-specific state updates (not managed by BLoC)
        setState(() {
          bannedUserModels.add(data);
          bannedUsers.add(data.targetId);
          adminModels.removeWhere((user) => user.id == data.targetId);
        });
        if (data.targetId == userId) {
          _handleHostDisconnection("You have been banned from this room.");
        }
        _showSnackBar(data.message, Colors.red);
      }
    });

    //Mute user
    _socketService.muteUserStream.listen((data) {
      if (mounted) {
        setState(() {
          // Store only the latest mute state which contains all muted users
          currentMuteState = data;
        });
        if (mounted) {
          _showSnackBar(
            "An ${data.lastUserIsMuted ? 'user is muted' : 'user is unmuted'} by admin",
            Colors.red,
          );
        }
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
    // Safely update bottom sheet only if it's still mounted and open
  if (mounted && CallManageBottomSheet.bottomSheetKey.currentState != null) {
      final callState = context.read<CallRequestBloc>().state;
      final pendingRequests = callState is CallRequestLoaded
          ? callState.pendingRequests
          : const <CallRequestModel>[];
      final activeBroadcasters = callState is CallRequestLoaded
          ? callState.activeBroadcasters
          : const <BroadcasterModel>[];

  CallManageBottomSheet.bottomSheetKey.currentState?.updateData(
        newCallers: pendingRequests,
        newInCallList: activeBroadcasters,
      );
    }
  }

  void _handleCallRequestState(CallRequestLoaded state) {
    final pendingRequests = state.pendingRequests;
    final activeBroadcasters = state.activeBroadcasters;

    // Notify for new pending requests
    final pendingIds = pendingRequests.map((request) => request.userId).toSet();
    final newRequests = pendingRequests
        .where((request) => !_knownPendingRequestIds.contains(request.userId))
        .toList();

    if (newRequests.isNotEmpty) {
      final request = newRequests.first;
      _showSnackBar(
        '📞 ${request.userDetails.name} wants to join the call',
        Colors.blue,
      );
      debugPrint(
        "📱 New call request: ${request.userDetails.name} (${request.userId})",
      );
    }

    _knownPendingRequestIds
      ..clear()
      ..addAll(pendingIds);

    _handleActiveBroadcasters(activeBroadcasters);

    _updateCallManageBottomSheet();
  }

  void _handleActiveBroadcasters(List<BroadcasterModel> broadcasters) {
    final hostId = isHost ? userId : widget.hostUserId;
    final broadcasterIds = broadcasters.map((b) => b.id).toSet();

    if (!isHost && hostId != null) {
      if (broadcasterIds.contains(hostId)) {
        _lastHostActivity = DateTime.now();
      } else if (_knownBroadcasterIds.contains(hostId)) {
        _handleHostDisconnection("Host disconnected. Live session ended.");
        return;
      }
    }

    if (!isHost && userId != null) {
      final isCurrentBroadcaster = broadcasterIds.contains(userId);
      if (isCurrentBroadcaster && !_isAudioCaller) {
        _promoteToAudioCaller();
      } else if (!isCurrentBroadcaster && _isAudioCaller) {
        _leaveAudioCaller();
      }
    }

    _knownBroadcasterIds
      ..clear()
      ..addAll(broadcasterIds);
  }

  /// Create a new room (for hosts)
  Future<void> _createRoom() async {
    if (userId == null) {
      debugPrint('❌ Cannot create room: userId is null');
      return;
    }

    // Use userId as the room name for dynamic room creation
    final dynamicRoomId = userId!;
    debugPrint('🏠 Creating room with dynamic name: $dynamicRoomId');

    // ✅ Dispatch BLoC event to create room
    context.read<LiveStreamBloc>().add(CreateRoom(
      title: "Demo Title",
      userId: userId!,
      roomType: RoomType.live,
    ));

    // Update local state for roomId (for Agora channel)
    setState(() {
      _currentRoomId = dynamicRoomId;
      roomId = dynamicRoomId;
    });

    // Now join the Agora channel with the dynamic room ID
    await _joinChannelWithDynamicToken();
  }

  /// Join an existing room
  Future<void> _joinRoom(String roomId) async {
    // ✅ Dispatch BLoC event to join room
    context.read<LiveStreamBloc>().add(JoinRoom(
      roomId: roomId,
      userId: userId ?? '',
    ));

    setState(() {
      _currentRoomId = roomId;
    });
  }

  /// Leave current room
  Future<void> _leaveRoom() async {
    if (_currentRoomId != null) {
      // ✅ Dispatch BLoC event to leave room
      context.read<LiveStreamBloc>().add(const LeaveRoom());

      if (mounted) {
        setState(() {
          _currentRoomId = null;
        });
      } else {
        _currentRoomId = null;
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
    final liveState = context.read<LiveStreamBloc>().state;
    final isMuted = liveState is LiveStreamStreaming ? !liveState.isMicEnabled : false;
    
    if ((isHost || _isAudioCaller) && !isMuted) {
      try {
        // ✅ Toggle microphone to mute (if currently unmuted)
        context.read<LiveStreamBloc>().add(ToggleMicrophone());
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
      // ✅ Dispatch BLoC event to delete/end stream
      context.read<LiveStreamBloc>().add(const EndLiveStream());

      setState(() {
        _currentRoomId = null;
      });
      // Navigate back or show end screen
      _endStream();
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
      // Remove current snackbar before showing a new one
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
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

    // Perform cleanup immediately
    // ✅ Timer now managed by LiveStreamBloc
    _hostActivityTimer?.cancel();
    
    // Leave the room to notify server
    _leaveRoom();

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
      "🔍 No video broadcasters detected - starting $_inactivityTimeoutSeconds second countdown...",
    );

    // Wait for inactivity timeout before considering host disconnected
    _hostActivityTimer = Timer(
      const Duration(seconds: _inactivityTimeoutSeconds),
      () {
        if (!mounted) return;

        // ✅ Get camera state from BLoC
        final liveState = context.read<LiveStreamBloc>().state;
        final isCameraEnabled = liveState is LiveStreamStreaming 
            ? liveState.isCameraEnabled 
            : false;

        // Double check that there are still no video broadcasters
        List<int> currentBroadcasters = [
          if (_remoteUid != null) _remoteUid!,
          ..._videoCallerUids,
          if (_isAudioCaller && isCameraEnabled) 0,
        ];

        if (currentBroadcasters.isEmpty) {
          debugPrint(
            "🚨 No video broadcasters for $_inactivityTimeoutSeconds seconds - host disconnected",
          );
          _handleHostDisconnection("Host disconnected. Live session ended.");
        } else {
          debugPrint("✅ Video broadcasters detected - host reconnected");
        }

        _hostActivityTimer = null;
      },
    );
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

      // If no activity detected for _inactivityTimeoutSeconds seconds, consider host disconnected
      if (lastActivity != null &&
          now.difference(lastActivity).inSeconds >= _inactivityTimeoutSeconds) {
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
  // bool _muted = false; // ✅ Moved to LiveStreamBloc.isMicrophoneEnabled
  bool _isInitializingCamera = false;

  // Video state management to prevent white screen
  bool _isVideoReady = false;
  bool _isLocalVideoReady = false;
  bool _isVideoConnecting = false;

  // Audio caller feature variables
  bool _isAudioCaller = false;
  final List<int> _audioCallerUids = [];
  final List<int> _videoCallerUids = []; // Track callers with video enabled
  final int _maxAudioCallers = 3;
  bool _isJoiningAsAudioCaller = false;
  // bool isCameraEnabled = false; // ✅ Moved to LiveStreamBloc.isCameraEnabled

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
            _isVideoConnecting = true; // Start video connection process
            // Don't set _remoteUid here - it should only be set when a remote user joins
          });

          // Apply camera preference AFTER successfully joining the channel
          debugPrint('🔍 onJoinChannelSuccess - isHost: $isHost');
          if (isHost) {
            debugPrint(
              '🔍 Calling _applyCameraPreference() from onJoinChannelSuccess',
            );
            _applyCameraPreference();

            // For hosts, local video should be ready after camera setup
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _isLocalVideoReady = true;
                  _isVideoReady = true;
                  _isVideoConnecting = false;
                });
                debugPrint('✅ Local video ready for host');
              }
            });
          } else {
            debugPrint('🔍 Not applying camera preference - user is not host');
          }

          // ✅ Stream timer now managed by LiveStreamBloc automatically
          // No need to start timer here

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
            // For viewers, set _remoteUid to the first user (likely the host)
            // But don't assume it's always the host since join order can vary
            if (_remoteUid == null && !isHost) {
              _remoteUid = remoteUid;
              debugPrint("🎯 Set _remoteUid to first joined user: $remoteUid");
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
              // Track remote video state for better user experience
              debugPrint(
                '📹 Remote video state changed: $state for UID: $remoteUid',
              );

              setState(() {
                if (state == RemoteVideoState.remoteVideoStateStarting ||
                    state == RemoteVideoState.remoteVideoStateDecoding) {
                  // User enabled video
                  if (!_videoCallerUids.contains(remoteUid) &&
                      remoteUid != _remoteUid) {
                    _videoCallerUids.add(remoteUid);
                  }

                  // Mark remote video as ready when decoding starts
                  if (state == RemoteVideoState.remoteVideoStateDecoding) {
                    // For viewers, any video broadcaster (host or caller) should trigger video readiness
                    // This fixes the issue where only the first joiner's video would be considered "ready"
                    if (!isHost) {
                      _isVideoReady = true;
                      _isVideoConnecting = false;
                      debugPrint(
                        '✅ Remote video ready for viewer (UID: $remoteUid)',
                      );
                    }
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

                    // For audio-only broadcasters (non-host), mark them as ready immediately
                    // since they won't have video and shouldn't show loading indicators
                    if (remoteUid != _remoteUid && !isHost) {
                      debugPrint(
                        '✅ Audio-only broadcaster $remoteUid marked as ready',
                      );
                    }
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

    // Optimize video settings for better performance and stability
    await _engine.enableVideo();
    await _engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 400,
      ),
    );

    // Only start preview for broadcasters with error handling
    if (isHost) {
      try {
        // Apply saved camera preference immediately for preview
        await _applyCameraPreference();
        await _engine.startPreview();
        debugPrint('✅ Video preview started successfully');
      } catch (e) {
        debugPrint('⚠️ Preview start failed: $e');
        // Continue without preview - video will start when joining channel
      }
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
        // _muted = false; // ✅ Removed - mic state managed by LiveStreamBloc
        _isJoiningAsAudioCaller = false;
      });
      
      // ✅ Ensure microphone is enabled via BLoC
      final liveState = context.read<LiveStreamBloc>().state;
      if (liveState is LiveStreamStreaming && !liveState.isMicEnabled) {
        context.read<LiveStreamBloc>().add(ToggleMicrophone());
      }

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
        // _muted = true; // ✅ Removed - mic state managed by LiveStreamBloc
      });
      
      // ✅ Ensure microphone is muted via BLoC when returning to audience
      final liveState = context.read<LiveStreamBloc>().state;
      if (liveState is LiveStreamStreaming && liveState.isMicEnabled) {
        context.read<LiveStreamBloc>().add(ToggleMicrophone());
      }

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

      // ✅ Dispatch BLoC event instead of setState
      context.read<LiveStreamBloc>().add(ToggleCamera());
      
      // Note: Agora SDK calls moved to BlocListener
    } catch (e) {
      debugPrint('❌ Error toggling camera: $e');
      _showSnackBar('❌ Failed to toggle camera', Colors.red);
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

      // ✅ Reset camera state to false for audio callers via BLoC
      final liveState = context.read<LiveStreamBloc>().state;
      if (liveState is LiveStreamStreaming && liveState.isCameraEnabled) {
        context.read<LiveStreamBloc>().add(ToggleCamera());
      }

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

      // ✅ Reset camera state via BLoC
      final liveState = context.read<LiveStreamBloc>().state;
      if (liveState is LiveStreamStreaming && liveState.isCameraEnabled) {
        context.read<LiveStreamBloc>().add(ToggleCamera());
      }

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
      // ✅ Dispatch BLoC event instead of setState
      context.read<LiveStreamBloc>().add(ToggleMicrophone());
      
      // Note: Agora SDK calls and snackbar moved to BlocListener
    } else {
      _showSnackBar(
        '🎤 Only hosts and audio callers can use microphone',
        Colors.orange,
      );
    }
  }

  // ✅ DEPRECATED: Stream timer now managed by LiveStreamBloc
  // Commented out to use BLoC's timer instead
  // Start stream timer
  // void _startStreamTimer() {
  //   // Only set start time if not already set (for existing streams)
  //   _streamStartTime ??= DateTime.now();
  //
  //   _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (mounted && _streamStartTime != null) {
  //       setState(() {
  //         _streamDuration = DateTime.now().difference(_streamStartTime!);
  //       });
  //
  //       // Check for bonus milestones for hosts only
  //       if (isHost &&
  //           _streamDuration.inMinutes >= _bonusIntervalMinutes &&
  //           !_isCallingBonusAPI) {
  //         int currentMilestone =
  //             (_streamDuration.inMinutes ~/ _bonusIntervalMinutes) *
  //             _bonusIntervalMinutes;
  //
  //         // Only call API if we've reached a new milestone
  //         if (currentMilestone > _lastBonusMilestone) {
  //           _callDailyBonusAPI();
  //         }
  //       }
  //     }
  //   });
  // }
  //
  // // Stop stream timer
  // void _stopStreamTimer() {
  //   _durationTimer?.cancel();
  //   _durationTimer = null;
  // }

  // Format duration to string
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // ✅ REMOVED: _playAnimation() - unused animation method

  // ✅ DEPRECATED: Call daily bonus API - Now handled by LiveStreamBloc
  // BLoC automatically calls bonus API at milestones via UpdateStreamDuration handler
  // For stream end, dispatch CallDailyBonus event
  // Commented out to use BLoC's implementation instead
  //
  // Future<void> _callDailyBonusAPI({bool isStreamEnd = false}) async {
  //   ... [old implementation commented out]
  // }

  // End live stream
  void _endLiveStream() async {
    try {
      // ✅ Capture context and auth state IMMEDIATELY before any async operations
      final canNavigate = mounted;
      AuthState? authState;
      if (canNavigate) {
        authState = context.read<AuthBloc>().state;
      }
      
      debugPrint("🔍 _endLiveStream: isHost=$isHost, canNavigate=$canNavigate, authState=$authState");
      
      // ✅ Timer now managed by LiveStreamBloc - will auto-cancel on EndLiveStream event

      // Reset audio caller state - only if widget is still mounted
      if (mounted) {
        setState(() {
          _isAudioCaller = false;
          _audioCallerUids.clear();
          _videoCallerUids.clear();
          _isJoiningAsAudioCaller = false;
          // isCameraEnabled = false; // ✅ Removed - managed by LiveStreamBloc
        });
      } else {
        // Update without setState if not mounted
        _isAudioCaller = false;
        _audioCallerUids.clear();
        _videoCallerUids.clear();
        _isJoiningAsAudioCaller = false;
        // isCameraEnabled = false; // ✅ Removed - managed by LiveStreamBloc
      }

      if (isHost) {
        // If host, delete the room
        await _deleteRoom();
      } else {
        // If viewer, leave the room
        await _leaveRoom();
      }
      
      // ✅ Use captured state instead of accessing context again
      if (isHost && canNavigate && authState is AuthAuthenticated) {
        debugPrint("✅ Host navigating to summary screen");
        
        // ✅ Call daily bonus API on stream end via BLoC
        if (mounted) {
          context.read<LiveStreamBloc>().add(const CallDailyBonus(isStreamEnd: true));
        }

        // Calculate total earned diamonds/coins
        int earnedDiamonds = 0;
        int totalGifts = 0;
        final giftState = context.read<GiftBloc>().state;
        if (giftState is GiftLoaded && userId != null) {
          earnedDiamonds = GiftModel.totalDiamondsForHost(
            giftState.gifts,
            userId!,
          );
          totalGifts = giftState.gifts.length;
        }

        debugPrint(
          "🏆 Host ending live stream - Total earned diamonds: $earnedDiamonds",
        );
        debugPrint("📊 Total gifts received: $totalGifts");

        // ✅ Check mounted one more time before final navigation
        if (mounted) {
          debugPrint("📍 About to navigate to liveSummary");
          context.go(
            AppRoutes.liveSummary,
            extra: {
              'userName': authState.user.name,
              'userId': authState.user.id.substring(0, 6),
              'earnedPoints': earnedDiamonds, // Pass actual earned diamonds
              'newFollowers': 0,
              'totalDuration': _formatDuration(_streamDuration),
              'userAvatar': authState.user.avatar,
            },
          );
        } else {
          debugPrint("⚠️ Widget not mounted, cannot navigate to summary");
        }
      } else if (!isHost && canNavigate) {
        debugPrint("✅ Viewer navigating back");
        // If viewer, just navigate back
        if (mounted) {
          context.go("/");
        }
      } else {
        debugPrint("⚠️ Cannot navigate: isHost=$isHost, canNavigate=$canNavigate, authState=$authState");
      }
    } catch (e) {
      debugPrint('❌ Error in _endLiveStream: $e');
      // Only pop if we didn't already navigate
      if (mounted) {
        debugPrint('📍 Fallback: popping due to error');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CallRequestBloc, CallRequestState>(
          listener: (context, state) {
            if (state is CallRequestLoaded) {
              _handleCallRequestState(state);
            } else if (state is CallRequestError) {
              _showSnackBar('❌ ${state.message}', Colors.red);
            } else if (state is CallRequestJoinSubmitted) {
              _showSnackBar(
                '🎤 Call request sent. Awaiting host approval...',
                Colors.blue,
              );
            }
          },
        ),
        // ✅ Listen to LiveStreamBloc for camera/mic changes
        BlocListener<LiveStreamBloc, LiveStreamState>(
          listenWhen: (previous, current) {
            // Only listen when in streaming state and camera/mic changed
            if (previous is LiveStreamStreaming && current is LiveStreamStreaming) {
              return previous.isCameraEnabled != current.isCameraEnabled ||
                     previous.isMicEnabled != current.isMicEnabled;
            }
            return false;
          },
          listener: (context, state) async {
            if (state is LiveStreamStreaming) {
              // Handle camera toggle
              if (_localUserJoined) {
                try {
                  await _engine.enableLocalVideo(state.isCameraEnabled);
                  await _engine.muteLocalVideoStream(!state.isCameraEnabled);
                  
                  if (state.isCameraEnabled) {
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
                  debugPrint('❌ Error applying camera state: $e');
                }
              }
              
              // Handle microphone toggle
              if (_localUserJoined) {
                try {
                  await _engine.muteLocalAudioStream(!state.isMicEnabled);
                  
                  if (!state.isMicEnabled) {
                    _showSnackBar('🔇 Microphone muted', Colors.orange);
                  } else {
                    _showSnackBar('🎤 Microphone unmuted', Colors.green);
                  }
                } catch (e) {
                  debugPrint('❌ Error applying microphone state: $e');
                }
              }
            }
          },
        ),
      ],
      child: PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // Only trigger cleanup if actually popping (not canceling)
        if (didPop) {
          _endLiveStream();
          debugPrint(
            'Back navigation invoked: '
            '(cleanup triggered)',
          );
        }
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

                  // ✅ Gift animation with BlocBuilder
                  if (_animationPlaying) 
                    BlocBuilder<GiftBloc, GiftState>(
                      builder: (context, giftState) {
                        final gifts = giftState is GiftLoaded 
                            ? giftState.gifts 
                            : <GiftModel>[];
                        return AnimatedLayer(gifts: gifts);
                      },
                    ),

                  // * This contaimer holds the livestream options,
                  SafeArea(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 30.h,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: NeverScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  children: [
                                    // this is the top row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                                widget.hostUserId?.substring(
                                                  0,
                                                  4,
                                                ) ??
                                                "Host",
                                            hostUserId: widget.hostUserId ?? "",
                                            currentUserId: state.user.id,
                                          ),
                                        Spacer(),
                                        // *show the viewers - ✅ Now using LiveStreamBloc state
                                        BlocBuilder<LiveStreamBloc, LiveStreamState>(
                                          builder: (context, liveState) {
                                            final viewers = liveState is LiveStreamStreaming 
                                                ? liveState.viewers 
                                                : <JoinedUserModel>[];
                                            
                                            return ActiveViewers(
                                              activeUserList: viewers,
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

                                        // * to show the leave button
                                        (isHost)
                                            ? GestureDetector(
                                                onTap: () {
                                                  EndStreamOverlay.show(
                                                    context,
                                                    onKeepStream: () {
                                                      debugPrint(
                                                        "Keep stream pressed",
                                                      );
                                                    },
                                                    onEndStream: () {
                                                      _endLiveStream();
                                                      debugPrint(
                                                        "End stream pressed",
                                                      );
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
                                                  debugPrint(
                                                    "Disconnect pressed",
                                                  );
                                                },
                                                child: Image.asset(
                                                  "assets/icons/live_exit_icon.png",
                                                  height: 50.h,
                                                ),
                                              ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),

                                    //  this is the second row TODO:  diamond and star count display
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        BlocBuilder<GiftBloc, GiftState>(
                                          builder: (context, giftState) {
                                            final hostId = isHost
                                                ? userId
                                                : widget.hostUserId;
                                            final gifts = giftState is GiftLoaded
                                                ? giftState.gifts
                                                : const <GiftModel>[];
                                            int diamondTotal = 0;
                                            if (hostId != null) {
                                              diamondTotal =
                                                  GiftModel.totalDiamondsForHost(
                                                gifts,
                                                hostId,
                                              );
                                            }

                                            return DiamondStarStatus(
                                              diamonCount: AppUtils.formatNumber(
                                                diamondTotal,
                                              ),
                                              starCount: AppUtils.formatNumber(0),
                                            );
                                          },
                                        ),
                                        SizedBox(height: 5.h),
                                        //add another widget to show the bonus
                                        // BonusStatus(
                                        //   bonusCount: AppUtils.formatNumber(
                                        //     _calculateTotalBonusDiamonds(),
                                        //   ),
                                        // ),
                                      ],
                                    ),

                                    Spacer(),

                                    // Chat widget - positioned at bottom left
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: BlocBuilder<ChatBloc, ChatState>(
                                        builder: (context, chatState) {
                                          final messages = chatState is ChatLoaded 
                                              ? chatState.messages 
                                              : <ChatModel>[];
                                          final callState = context.watch<CallRequestBloc>().state;
                                          final isCallingNow = callState is CallRequestLoaded &&
                                              callState.activeBroadcasters.isNotEmpty;
                                          return LiveChatWidget(
                                            isCallingNow: isCallingNow,
                                            messages: messages,
                                          );
                                        },
                                      ),
                                    ),

                                    SizedBox(height: 10.h),

                                    // the bottom buttons
                                    if (isHost)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
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
                                            iconPath:
                                                "assets/icons/gift_user_icon.png",
                                            onTap: () {
                                              // ✅ Get viewers from BLoC state
                                              final liveState = context.read<LiveStreamBloc>().state;
                                              final viewers = liveState is LiveStreamStreaming 
                                                  ? liveState.viewers 
                                                  : <JoinedUserModel>[];
                                              
                                              showGiftBottomSheet(
                                                context,
                                                activeViewers: viewers,
                                                roomId:
                                                    _currentRoomId ?? roomId,
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
                                            iconPath:
                                                "assets/icons/pk_icon.png",
                                            onTap: () {
                                              // _playAnimation();
                                              _showSnackBar(
                                                '🎶 Not implemented yet',
                                                Colors.green,
                                              );
                                              // showMusicBottomSheet(context);
                                            },
                                          ),
                                          BlocBuilder<LiveStreamBloc, LiveStreamState>(
                                            builder: (context, liveState) {
                                              final isMuted = liveState is LiveStreamStreaming 
                                                  ? !liveState.isMicEnabled 
                                                  : true;
                                              return CustomLiveButton(
                                                iconPath: isMuted
                                                    ? "assets/icons/mute_icon.png"
                                                    : "assets/icons/unmute_icon.png",
                                                onTap: () {
                                                  _toggleMute();
                                                },
                                              );
                                            },
                                          ),
                                          CustomLiveButton(
                                            iconPath:
                                                "assets/icons/call_icon.png",
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
                                              // Capture the outer context with BLoC access
                                              final outerContext = context;
                                              final callRequestBloc =
                                                  outerContext.read<CallRequestBloc>();

                                              showModalBottomSheet(
                                                context: outerContext,
                                                useRootNavigator: false,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (sheetContext) {
                                                  return BlocProvider.value(
                                                    value: callRequestBloc,
                                                    child: BlocBuilder<CallRequestBloc,
                                                        CallRequestState>(
                                                      builder: (context,
                                                          callRequestState) {
                                                        final pendingRequests =
                                                            callRequestState
                                                                    is CallRequestLoaded
                                                                ? callRequestState
                                                                    .pendingRequests
                                                                : <CallRequestModel>[];
                                                        final activeBroadcasters =
                                                            callRequestState
                                                                    is CallRequestLoaded
                                                                ? callRequestState
                                                                    .activeBroadcasters
                                                                : <BroadcasterModel>[];

                                                        return CallManageBottomSheet(
                                                          key: CallManageBottomSheet
                                                              .bottomSheetKey,
                                                          onAcceptCall: (userId) {
                                                            debugPrint(
                                                              "Accepting call request from $userId",
                                                            );
                                                            callRequestBloc.add(
                                                              AcceptCallRequest(
                                                                userId: userId,
                                                                roomId:
                                                                    _currentRoomId ??
                                                                        '',
                                                              ),
                                                            );
                                                            _updateCallManageBottomSheet();
                                                          },
                                                          onRejectCall: (userId) {
                                                            debugPrint(
                                                              "Rejecting call request from $userId",
                                                            );
                                                            callRequestBloc.add(
                                                              RejectCallRequest(
                                                                userId: userId,
                                                                roomId:
                                                                    _currentRoomId ??
                                                                        '',
                                                              ),
                                                            );
                                                            _updateCallManageBottomSheet();
                                                          },
                                                          onKickUser: (userId) {
                                                            callRequestBloc.add(
                                                              RemoveBroadcaster(
                                                                userId: userId,
                                                                roomId:
                                                                    _currentRoomId ??
                                                                        '',
                                                              ),
                                                            );
                                                            debugPrint(
                                                              "Kicking user $userId from call",
                                                            );
                                                            _updateCallManageBottomSheet();
                                                          },
                                                          callers: pendingRequests,
                                                          inCallList:
                                                              activeBroadcasters,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),

                                          CustomLiveButton(
                                            iconPath:
                                                "assets/icons/menu_icon.png",
                                            onTap: () {
                                              // ✅ Get duration from BLoC state
                                              final liveState = context.read<LiveStreamBloc>().state;
                                              final streamDuration = liveState is LiveStreamStreaming 
                                                  ? liveState.duration 
                                                  : Duration.zero;
                                              
                                              showGameBottomSheet(
                                                context,
                                                userId: userId,
                                                isHost: isHost,
                                                streamDuration: streamDuration,
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
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
                                            iconPath:
                                                "assets/icons/gift_user_icon.png",
                                            onTap: () {
                                              // ✅ Get viewers from BLoC state
                                              final liveState = context.read<LiveStreamBloc>().state;
                                              final viewers = liveState is LiveStreamStreaming 
                                                  ? liveState.viewers 
                                                  : <JoinedUserModel>[];
                                              
                                              showGiftBottomSheet(
                                                context,
                                                activeViewers: viewers,
                                                roomId:
                                                    _currentRoomId ?? roomId,
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
                                            iconPath:
                                                "assets/icons/game_user_icon.png",
                                            onTap: () {
                                              // ✅ Get duration from BLoC state
                                              final liveState = context.read<LiveStreamBloc>().state;
                                              final streamDuration = liveState is LiveStreamStreaming 
                                                  ? liveState.duration 
                                                  : Duration.zero;
                                              
                                              showGameBottomSheet(
                                                context,
                                                userId: userId,
                                                streamDuration: streamDuration,
                                              );
                                            },
                                            height: 40.h,
                                          ),
                                          CustomLiveButton(
                                            iconPath:
                                                "assets/icons/share_user_icon.png",
                                            onTap: () {},
                                            height: 40.h,
                                          ),
                                          CustomLiveButton(
                                            iconPath:
                                                "assets/icons/menu_icon.png",
                                            onTap: () {
                                              final liveState = context.read<LiveStreamBloc>().state;
                                              final isMuted = liveState is LiveStreamStreaming 
                                                  ? !liveState.isMicEnabled 
                                                  : true;
                                              showMenuBottomSheet(
                                                context,
                                                userId: userId,
                                                isHost: isHost,
                                                isMuted: isMuted,
                                                isAdminMuted:
                                                    _isCurrentUserMuted(),
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
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 140.h,
                    right: 30.w,
                    child: BlocBuilder<CallRequestBloc, CallRequestState>(
                      builder: (context, callState) {
                        final hostId = isHost ? userId : widget.hostUserId;
                        final broadcasters = callState is CallRequestLoaded
                            ? callState.activeBroadcasters
                            : const <BroadcasterModel>[];

                        final displayBroadcasters = broadcasters
                            .where((b) => b.id != hostId)
                            .toList();

                        WhoAmI resolveRole(String broadcasterId) {
                          final authState = context.read<AuthBloc>().state;
                          final currentUserId =
                              authState is AuthAuthenticated
                                  ? authState.user.id
                                  : userId;

                          if (_isCurrentUserAdmin()) {
                            return WhoAmI.admin;
                          } else if (_isCurrentUserHost()) {
                            return WhoAmI.host;
                          } else if (broadcasterId == currentUserId) {
                            return WhoAmI.myself;
                          } else {
                            return WhoAmI.user;
                          }
                        }

                        final currentRoomId = _currentRoomId ?? roomId;
                        final callRequestBloc =
                            context.read<CallRequestBloc>();

                        final children = <Widget>[
                          ...displayBroadcasters.map((broadcaster) {
                            return CallOverlayWidget(
                              whoAmI: resolveRole(broadcaster.id),
                              userId: broadcaster.id,
                              userName: broadcaster.name,
                              userImage: broadcaster.avatar.isNotEmpty
                                  ? broadcaster.avatar
                                  : null,
                              onDisconnect: () {
                                if (currentRoomId.isEmpty) {
                                  _showSnackBar(
                                    '❌ Room not ready, please try again',
                                    Colors.red,
                                  );
                                  return;
                                }

                                callRequestBloc.add(
                                  RemoveBroadcaster(
                                    userId: broadcaster.id,
                                    roomId: currentRoomId,
                                  ),
                                );
                              },
                              onMute: () {
                                _muteUser(broadcaster.id);
                              },
                              onManage: () {
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
                          }).toList(),
                        ];

                        if (!isHost) {
                          children.add(SizedBox(height: 80.h));
                          if (displayBroadcasters.isNotEmpty) {
                            children.add(
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
                                  '🎤 ${displayBroadcasters.length}/$_maxAudioCallers',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          children.add(
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
                                  final currentUserId = userId;
                                  if (currentUserId == null ||
                                      currentUserId.isEmpty ||
                                      currentRoomId.isEmpty) {
                                    _showSnackBar(
                                      '❌ Unable to leave call right now',
                                      Colors.red,
                                    );
                                    return;
                                  }

                                  callRequestBloc.add(
                                    RemoveBroadcaster(
                                      userId: currentUserId,
                                      roomId: currentRoomId,
                                    ),
                                  );
                                  debugPrint("Leaving audio caller");
                                } else {
                                  if (currentRoomId.isEmpty) {
                                    _showSnackBar(
                                      '❌ Room not ready, please try again',
                                      Colors.red,
                                    );
                                    return;
                                  }

                                  callRequestBloc.add(
                                    SubmitJoinCallRequest(
                                      roomId: currentRoomId,
                                    ),
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
                                              ? const Color(0xFFFEB86F)
                                              : const Color(0xFFFEB86F),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _isJoiningAsAudioCaller
                                        ? SizedBox(
                                            width: 40.w,
                                            height: 40.h,
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
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
                          );
                        } else {
                          children.add(SizedBox(height: 180.h));
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: children,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      ), // ✅ Closing PopScope
    ); // ✅ Closing MultiBlocListener
  }

  // Main video view with multi-broadcaster support
  Widget _buildVideoView() {
    // Show loading indicator during camera initialization
    if (_isInitializingCamera) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    // Show connecting indicator while video is establishing
    if (_isVideoConnecting && !_isVideoReady) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
    // ✅ Get camera state from BLoC
    final liveState = context.read<LiveStreamBloc>().state;
    final isCameraEnabled = liveState is LiveStreamStreaming 
        ? liveState.isCameraEnabled 
        : false;
    
    // Get all video broadcasters including all remote users who could have video
    List<int> allVideoBroadcasters = [
      // Include all remote users as potential video sources
      ..._remoteUsers,
      if (_isAudioCaller && isCameraEnabled)
        0, // Own video if audio caller with camera on
    ];

    // For viewers, show video if any remote users are present and video is ready
    // OR if we're still connecting but have remote users
    bool shouldShowVideo =
        allVideoBroadcasters.isNotEmpty && (_isVideoReady || _localUserJoined);

    if (!shouldShowVideo) {
      // Start host disconnection monitoring when no video broadcasters are present
      if (!isHost) {
        _startHostDisconnectionMonitoring(); //TODO: Implement host disconnection monitoring
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
    // Since only host shows video and others are audio-only callers,
    // always prioritize host's video and show it in full screen

    // Find the best UID to display
    int displayUid;
    if (isHost) {
      displayUid = 0; // Local video for host
    } else {
      // For viewers, use the first available remote user
      // This could be host or any broadcaster with video
      displayUid = broadcasterUids.isNotEmpty ? broadcasterUids[0] : 0;
    }

    return _buildSingleVideoView(displayUid, isHostView: isHostView);
  }

  /// Single broadcaster view with video readiness checks
  Widget _buildSingleVideoView(int uid, {required bool isHostView}) {
    if (uid == 0) {
      // Local video (host or audio caller with camera)
      return Stack(
        children: [
          // Video view
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
          // Show loading overlay if local video is not ready
          if (!_isLocalVideoReady && isHost)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      );
    } else {
      // Remote video - always show video view for any remote user
      // The video readiness is now handled globally, not per-user
      bool shouldShowVideoLoading = !_isVideoReady && !isHost;

      return Stack(
        children: [
          // Always show video view for remote users
          // Let Agora handle which user's video is actually displayed
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: uid),
              connection: RtcConnection(channelId: roomId),
            ),
          ),
          // Show loading overlay only when video is not ready
          if (shouldShowVideoLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      );
    }
  }

  @override
  void dispose() {
    debugPrint("🧹 Disposing video live screen...");
    
    // ✅ Timer now managed by LiveStreamBloc - will auto-cleanup
    _hostActivityTimer?.cancel();

    // Cancel all stream subscriptions to prevent setState calls after disposal
    _connectionStatusSubscription?.cancel();
    _roomCreatedSubscription?.cancel();
    _roomJoinedSubscription?.cancel();
    _roomLeftSubscription?.cancel();
    _roomDeletedSubscription?.cancel();
    _errorSubscription?.cancel();

    // Cancel additional socket stream subscriptions
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _sentMessageSubscription?.cancel();
    _sentGiftSubscription?.cancel();
    _bannedListSubscription?.cancel();
    _bannedUserSubscription?.cancel();

    // Dispose other resources
    _titleController.dispose();
    
    // Cleanup Agora engine and resources without accessing context
    _disposeAgoraEngine();

    // ✅ Clear all state variables for next stream
    activeViewers.clear();
  _knownPendingRequestIds.clear();
  _knownBroadcasterIds.clear();
    bannedUsers.clear();
    bannedUserModels.clear();
    currentMuteState = null;
    adminModels.clear();
    _chatMessages.clear();
    
    debugPrint("✅ Video live screen disposed");
    super.dispose();
  }

  /// Safely dispose Agora engine without accessing context
  void _disposeAgoraEngine() {
    try {
      _engine.leaveChannel();
      _engine.release();
      debugPrint("✅ Agora engine disposed safely");
    } catch (e) {
      debugPrint("⚠️ Error disposing Agora engine: $e");
    }
  }
}
