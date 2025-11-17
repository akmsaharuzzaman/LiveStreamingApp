import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/broadcaster_model.dart';
import 'package:dlstarlive/core/network/models/call_request_model.dart';
import 'package:dlstarlive/core/network/models/chat_model.dart';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/features/live/presentation/bloc/bloc.dart';
import 'package:dlstarlive/features/live/presentation/component/gift_bottom_sheet.dart';
import 'package:dlstarlive/features/live/presentation/component/send_message_buttonsheet.dart';
import 'package:dlstarlive/features/live/presentation/widgets/call_overlay_widget.dart';
import 'package:dlstarlive/injection/injection.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/models/joined_user_model.dart';
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
            ..add(
              InitializeLiveStream(
                roomId: roomId,
                hostUserId: hostUserId,
                isHost: (roomId ?? '').isEmpty,
                // If roomId is empty, we are creating a new stream (host)
                // ✅ Pass initial duration from existing room data
                // This makes duration counter continue from where stream elapsed, not from zero
                initialDurationSeconds: roomData?.duration ?? 0,
              ),
            ),
        ),
        BlocProvider<ChatBloc>(
          create: (context) =>
              getIt<ChatBloc>()..add(const LoadInitialMessages([])),
        ),
        BlocProvider<GiftBloc>(
          create: (context) =>
              getIt<GiftBloc>()..add(const LoadInitialGifts([])),
        ),
        BlocProvider<CallRequestBloc>(
          create: (context) =>
              getIt<CallRequestBloc>()..add(const LoadInitialBroadcasters([])),
        ),
        BlocProvider<ModerationBloc>(
          create: (context) => getIt<ModerationBloc>(),
        ),
        BlocProvider<LiveSessionCubit>(
          create: (context) => getIt<LiveSessionCubit>(),
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

  LiveSessionState get _sessionState => context.read<LiveSessionCubit>().state;

  String _getAudioCallerText(LiveSessionState sessionState) {
    if (sessionState.isJoiningAudioCaller) {
      return 'Joining...';
    }
    return sessionState.isAudioCaller ? 'Leave' : 'Join';
  }

  void _toggleMute() {
    final sessionState = _sessionState;
    if (sessionState.isHost || sessionState.isAudioCaller) {
      context.read<LiveStreamBloc>().add(const ToggleMicrophone());
    } else {
      _showSnackBar(
        '🎤 Only hosts and audio callers can use microphone',
        Colors.orange,
      );
    }
  }

  String? _currentRoomId;
  String? userId;
  bool isHost = true;
  String roomId = "default_channel";
  final Set<String> _knownPendingRequestIds = {};
  final Set<String> _knownBroadcasterIds = {};

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
  // Host activity tracking for viewers
  bool _animationPlaying = false;
  Timer? _giftAnimationTimer;
  int _lastGiftCount = 0;

  // Chat messages
  final List<ChatModel> _chatMessages = [];

  // ✅ Track previous viewers for detecting disconnects
  List<JoinedUserModel> _previousViewers = [];

  @override
  void initState() {
    super.initState();
    _resetState(); // ✅ Reset all state before initializing
    _initializeFromRoomData(); // Initialize from existing room data
    _initializeExistingViewers();
    extractRoomId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndDispatchEvent();
      // Initialize _previousViewers after first build to track future changes
      Future.delayed(Duration(milliseconds: 100), () {
        final liveStreamState = context.read<LiveStreamBloc>().state;
        if (liveStreamState is LiveStreamStreaming) {
          _previousViewers = List.from(liveStreamState.viewers);
          debugPrint(
            "📊 [INIT] Initial viewers snapshot: ${_previousViewers.map((v) => v.name).toList()}",
          );
        }
      });
    });
  }

  /// ✅ Reset all state variables to clean slate
  void _resetState() {
    debugPrint("🔄 Resetting screen state...");
    _knownPendingRequestIds.clear();
    _knownBroadcasterIds.clear();
    _chatMessages.clear();
    // ✅ Duration now managed by LiveStreamBloc
    _streamDuration = Duration.zero;
    _lastBonusMilestone = 0;
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
        context.read<ChatBloc>().add(
          LoadInitialMessages(List.from(_chatMessages)),
        );
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
          context.read<CallRequestBloc>().add(
            LoadInitialBroadcasters(initialBroadcasters),
          );
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

        context.read<CallRequestBloc>().add(
          LoadCallRequestList(initialRequests),
        );
        debugPrint(
          "📞 Loaded ${initialRequests.length} existing call requests",
        );
      }

      // Initialize members as active viewers (excluding host)
      if (roomData.membersDetails.isNotEmpty) {
        final initialViewers = <JoinedUserModel>[];
        for (var member in roomData.membersDetails) {
          // Don't add host to viewers list
          if (member.id != roomData.hostId) {
            initialViewers.add(
              JoinedUserModel(
                id: member.id,
                avatar: member.avatar,
                name: member.name,
                uid: member.uid,
                currentLevel: member.currentLevel,
                currentBackground: member.currentBackground,
                currentTag: member.currentTag,
                diamonds: 0,
              ),
            );
          }
        }

        if (initialViewers.isNotEmpty) {
          _seedInitialViewers(initialViewers);
        }

        debugPrint(
          "👥 Loaded ${initialViewers.length} existing members as viewers",
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
      final initialViewers = widget.existingViewers
          .where((hostDetail) => hostDetail.id != widget.hostUserId)
          .map(
            (hostDetail) => JoinedUserModel(
              id: hostDetail.id,
              avatar: hostDetail.avatar,
              name: hostDetail.name,
              uid: hostDetail.uid,
              currentLevel: hostDetail.currentLevel,
              currentBackground: hostDetail.currentBackground,
              currentTag: hostDetail.currentTag,
              diamonds: 0,
            ),
          )
          .toList();

      if (initialViewers.isNotEmpty) {
        _seedInitialViewers(initialViewers);
      }

      debugPrint(
        "Initialized ${initialViewers.length} existing viewers (host excluded)",
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
        _lastGiftCount = 1;
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

      // Start live session orchestration via cubit
      await context.read<LiveSessionCubit>().initializeSession(
        isHost: isHost,
        initialRoomId: isHost ? null : widget.roomId,
        userId: uid,
      );
    } else {
      debugPrint("User ID is null, cannot initialize live streaming");
    }
  }

  void _seedInitialViewers(List<JoinedUserModel> viewers) {
    if (viewers.isEmpty) {
      return;
    }

    context.read<LiveStreamBloc>().add(SeedInitialViewers(viewers));
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
  }

  void _handleActiveBroadcasters(List<BroadcasterModel> broadcasters) {
    final hostId = isHost ? userId : widget.hostUserId;
    final broadcasterIds = broadcasters.map((b) => b.id).toSet();
    final sessionCubit = context.read<LiveSessionCubit>();
    final sessionState = sessionCubit.state;

    if (!isHost && hostId != null) {
      final hostStillActive = broadcasterIds.contains(hostId);
      if (!hostStillActive && _knownBroadcasterIds.contains(hostId)) {
        _handleHostDisconnection("Host disconnected. Live session ended.");
        return;
      }
    }

    if (!isHost && userId != null) {
      final isCurrentBroadcaster = broadcasterIds.contains(userId);
      if (isCurrentBroadcaster) {
        context.read<CallRequestBloc>().add(ResolvePendingRequest(userId!));
        if (!sessionState.isAudioCaller) {
          sessionCubit.promoteToAudioCaller();
        }
      } else if (sessionState.isAudioCaller) {
        sessionCubit.leaveAudioCaller();
      }
    }

    _knownBroadcasterIds
      ..clear()
      ..addAll(broadcasterIds);
  }

  void _triggerGiftAnimation() {
    _giftAnimationTimer?.cancel();

    if (mounted && !_animationPlaying) {
      setState(() {
        _animationPlaying = true;
      });
    }
  }

  //Sent/Send Message
  void _emitMessageToSocket(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final sessionState = _sessionState;
    final roomIdentifier =
        sessionState.currentRoomId ?? _currentRoomId ?? roomId;

    if (roomIdentifier.isEmpty) {
      _showSnackBar('❌ Room not ready, please try again', Colors.red);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showSnackBar('👤 Please log in to send messages', Colors.orange);
      return;
    }

    context.read<ChatBloc>().add(
      SendChatMessage(
        roomId: roomIdentifier,
        userId: authState.user.id,
        userName: authState.user.name,
        message: trimmed,
        avatar: authState.user.avatar,
      ),
    );
  }

  // Make Admin
  void _makeAdmin(String userId) {
    final currentRoom = _currentRoomId ?? roomId;
    if (currentRoom.isEmpty) {
      _showSnackBar('❌ Room not ready, please try again', Colors.red);
      return;
    }

    context.read<ModerationBloc>().add(
      ModerationToggleAdmin(roomId: currentRoom, userId: userId),
    );
  }

  // Remove Admin
  void _removeAdmin(String userId) {
    final currentRoom = _currentRoomId ?? roomId;
    if (currentRoom.isEmpty) {
      _showSnackBar('❌ Room not ready, please try again', Colors.red);
      return;
    }

    context.read<ModerationBloc>().add(
      ModerationToggleAdmin(roomId: currentRoom, userId: userId),
    );
  }

  /// Ban User
  void _banUser(String userId) {
    final currentRoom = _currentRoomId ?? roomId;
    if (currentRoom.isEmpty) {
      _showSnackBar('❌ Room not ready, please try again', Colors.red);
      return;
    }

    context.read<ModerationBloc>().add(
      ModerationBanUser(roomId: currentRoom, userId: userId),
    );
  }

  /// Mute User
  void _muteUser(String userId) {
    final currentRoom = _currentRoomId ?? roomId;
    if (currentRoom.isEmpty) {
      _showSnackBar('❌ Room not ready, please try again', Colors.red);
      return;
    }

    context.read<ModerationBloc>().add(
      ModerationMuteUser(roomId: currentRoom, userId: userId),
    );
  }

  /// Check if current user is in the muted users list
  bool _isCurrentUserMuted(ModerationState moderationState) {
    if (userId == null || moderationState.muteState == null) return false;

    // Check if current user is in the complete list of muted users
    return moderationState.muteState!.allMutedUsersList.contains(userId);
  }

  /// Force mute current user when they are administratively muted
  void _forceMuteCurrentUser(ModerationState moderationState) {
    final liveState = context.read<LiveStreamBloc>().state;
    final isMuted = liveState is LiveStreamStreaming
        ? !liveState.isMicEnabled
        : false;
    final sessionState = _sessionState;
    final isAuthorized = sessionState.isHost || sessionState.isAudioCaller;

    if (isAuthorized && !isMuted && _isCurrentUserMuted(moderationState)) {
      context.read<LiveStreamBloc>().add(const ToggleMicrophone());
      _showSnackBar('🔇 You have been muted by an admin', Colors.red);
      debugPrint('Current user force muted by admin');
    }
  }

  /// Check if current user is an admin
  bool _isCurrentUserAdmin(ModerationState moderationState) {
    final currentUserId = userId;
    if (currentUserId == null) {
      return false;
    }

    return moderationState.adminList.any((admin) => admin.id == currentUserId);
  }

  /// Check if current user is the host
  bool _isCurrentUserHost() {
    return isHost;
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

  /// Handle session-level force exit events surfaced by the cubit
  void _handleHostDisconnection(String reason) {
    if (!mounted) {
      return;
    }

    debugPrint("🚨 $reason - Exiting live screen...");
    _showSnackBar('📱 $reason', Colors.red);

    // Delegate cleanup to cubit so Agora/socket teardown stays centralized
    context.read<LiveSessionCubit>().endSession(notifyServer: false);

    // Give the user a moment to read the message before leaving
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
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
      final sessionCubit = context.read<LiveSessionCubit>();
      final liveStreamBloc = context.read<LiveStreamBloc>();
      final sessionState = sessionCubit.state;
      final isHostSession = sessionState.isHost;
      final authState = context.read<AuthBloc>().state;
      final auth = authState is AuthAuthenticated ? authState : null;
      final canNavigate = mounted;

      final liveStateBeforeEnd = liveStreamBloc.state;

      await sessionCubit.endSession(notifyServer: false);

      if (isHostSession) {
        debugPrint('Host ending live stream');
        liveStreamBloc.add(const EndLiveStream());
      } else {
        debugPrint('Audience leaving room');
        liveStreamBloc.add(const LeaveRoom());
      }

      if (!canNavigate) {
        return;
      }

      if (isHostSession && auth != null) {
        // ✅ Daily bonus API is now called automatically in EndLiveStream event handler
        // No need to call separately here

        final giftState = context.read<GiftBloc>().state;
        int earnedDiamonds = 0;
        int totalGifts = 0;
        if (giftState is GiftLoaded) {
          earnedDiamonds = GiftModel.totalDiamondsForHost(
            giftState.gifts,
            auth.user.id,
          );
          totalGifts = giftState.gifts.length;
        }

        final totalDuration = liveStateBeforeEnd is LiveStreamStreaming
            ? liveStateBeforeEnd.duration
            : _streamDuration;

        context.go(
          AppRoutes.liveSummary,
          extra: {
            'userName': auth.user.name,
            'userId': auth.user.id.substring(0, 6),
            'earnedPoints': earnedDiamonds,
            'newFollowers': 0,
            'totalDuration': _formatDuration(totalDuration),
            'userAvatar': auth.user.avatar,
            'totalGifts': totalGifts,
          },
        );
        return;
      }

      if (!isHostSession) {
        context.go('/');
      }
    } catch (e) {
      debugPrint('❌ Error in _endLiveStream: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LiveSessionCubit, LiveSessionState>(
          listenWhen: (previous, current) =>
              previous.snackBar != current.snackBar,
          listener: (context, state) {
            final snackBar = state.snackBar;
            if (snackBar == null) {
              return;
            }

            Color color;
            switch (snackBar.type) {
              case LiveSessionSnackBarType.success:
                color = Colors.green;
                break;
              case LiveSessionSnackBarType.error:
                color = Colors.red;
                break;
              case LiveSessionSnackBarType.warning:
                color = Colors.orange;
                break;
              case LiveSessionSnackBarType.info:
                color = Colors.blueGrey;
                break;
            }

            _showSnackBar(snackBar.message, color);
            context.read<LiveSessionCubit>().clearSnackBar();
          },
        ),
        BlocListener<LiveSessionCubit, LiveSessionState>(
          listenWhen: (previous, current) =>
              previous.forceExitReason != current.forceExitReason,
          listener: (context, state) {
            final reason = state.forceExitReason;
            if (reason != null && reason.isNotEmpty) {
              _handleHostDisconnection(reason);
              context.read<LiveSessionCubit>().clearForceExitReason();
            }
          },
        ),
        BlocListener<LiveSessionCubit, LiveSessionState>(
          listenWhen: (previous, current) =>
              previous.currentRoomId != current.currentRoomId,
          listener: (context, state) {
            final roomId = state.currentRoomId;
            if (roomId != null && roomId.isNotEmpty) {
              if (mounted) {
                setState(() {
                  _currentRoomId = roomId;
                  this.roomId = roomId;
                });
              }
              context.read<LiveStreamBloc>().add(UpdateActiveRoom(roomId));
            }
          },
        ),
        BlocListener<LiveSessionCubit, LiveSessionState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == LiveSessionStatus.error,
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              _showSnackBar('❌ ${state.errorMessage}', Colors.red);
            }
          },
        ),
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
        BlocListener<GiftBloc, GiftState>(
          listener: (context, state) {
            if (state is GiftLoaded) {
              if (state.gifts.length > _lastGiftCount) {
                _triggerGiftAnimation();
              }
              _lastGiftCount = state.gifts.length;
            } else if (state is GiftInitial) {
              _lastGiftCount = 0;
            }
          },
        ),
        BlocListener<ModerationBloc, ModerationState>(
          listener: (context, state) {
            if (!mounted) return;

            if (state.bannedUserIds.contains(userId)) {
              _handleHostDisconnection('You have been banned from this room.');
            }

            if (_isCurrentUserMuted(state)) {
              _forceMuteCurrentUser(state);
            }

            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              _showSnackBar('❌ ${state.errorMessage}', Colors.red);
            } else if (state.successMessage != null &&
                state.successMessage!.isNotEmpty) {
              Color color;
              switch (state.lastAction) {
                case ModerationAction.muteRequested:
                case ModerationAction.muteStateUpdated:
                  color = Colors.orange;
                  break;
                case ModerationAction.adminToggled:
                case ModerationAction.adminUpdated:
                  color = Colors.blue;
                  break;
                default:
                  color = Colors.red;
              }
              _showSnackBar(state.successMessage!, color);
            }

            if ((state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) ||
                (state.successMessage != null &&
                    state.successMessage!.isNotEmpty)) {
              context.read<ModerationBloc>().add(
                const ModerationClearNotification(),
              );
            }
          },
        ),
        // ✅ Listen to LiveStreamBloc for camera/mic changes
        BlocListener<LiveStreamBloc, LiveStreamState>(
          listenWhen: (previous, current) {
            // Only listen when in streaming state and camera/mic changed
            if (previous is LiveStreamStreaming &&
                current is LiveStreamStreaming) {
              return previous.isCameraEnabled != current.isCameraEnabled ||
                  previous.isMicEnabled != current.isMicEnabled;
            }
            return false;
          },
          listener: (context, state) async {
            if (state is LiveStreamStreaming) {
              final sessionCubit = context.read<LiveSessionCubit>();
              final sessionState = sessionCubit.state;

              if (sessionState.localUserJoined) {
                try {
                  await sessionCubit.applyCameraState(state.isCameraEnabled);

                  if (state.isCameraEnabled) {
                    _showSnackBar(
                      '📷 Camera turned on - You are now visible!',
                      Colors.green,
                    );
                  } else {
                    _showSnackBar(
                      '📷 Camera turned off - Audio only mode',
                      Colors.orange,
                    );
                  }
                } catch (error) {
                  debugPrint('❌ Error applying camera state: $error');
                }

                try {
                  await sessionCubit.applyMicrophoneState(state.isMicEnabled);

                  if (!state.isMicEnabled) {
                    _showSnackBar('🔇 Microphone muted', Colors.orange);
                  } else {
                    _showSnackBar('🎤 Microphone unmuted', Colors.green);
                  }
                } catch (error) {
                  debugPrint('❌ Error applying microphone state: $error');
                }
              }
            }
          },
        ),
        // ✅ Listen for viewer changes and remove disconnected users from call list
        BlocListener<LiveStreamBloc, LiveStreamState>(
          listenWhen: (previous, current) {
            // Only listen when in streaming state
            if (previous is LiveStreamStreaming &&
                current is LiveStreamStreaming) {
              // Trigger when viewers list changes
              return previous.viewers != current.viewers;
            }
            return false;
          },
          listener: (context, state) {
            if (state is LiveStreamStreaming) {
              // Find viewers that were in _previousViewers but not in current state.viewers
              for (var oldViewer in _previousViewers) {
                bool stillExists = state.viewers.any(
                  (v) => v.id == oldViewer.id,
                );
                if (!stillExists) {
                  // This user left - remove from call requests
                  debugPrint(
                    "🚪 [DISCONNECT] Viewer ${oldViewer.name} (${oldViewer.id}) left stream - removing from all calls",
                  );
                  context.read<CallRequestBloc>().add(
                    UserDisconnected(oldViewer.id),
                  );
                }
              }

              // Update _previousViewers to current viewers
              _previousViewers = List.from(state.viewers);
            }
          },
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) {
            return;
          }

          _endLiveStream();
          debugPrint('Back navigation invoked: (cleanup triggered)');
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
              final sessionState = context.watch<LiveSessionCubit>().state;
              return Scaffold(
                body: Stack(
                  children: [
                    _buildVideoView(sessionState),

                    // ✅ Gift animation with BlocBuilder
                    if (_animationPlaying)
                      BlocBuilder<GiftBloc, GiftState>(
                        builder: (context, giftState) {
                          final gifts = giftState is GiftLoaded
                              ? giftState.gifts
                              : <GiftModel>[];
                          return AnimatedLayer(
                            gifts: gifts,
                            onCompleted: () {
                              if (mounted) {
                                setState(() {
                                  _animationPlaying = false;
                                });
                              }
                            },
                          );
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
                                              hostUserId:
                                                  widget.hostUserId ?? "",
                                              currentUserId: state.user.id,
                                            ),
                                          Spacer(),
                                          // *show the viewers - ✅ Now using LiveStreamBloc state
                                          BlocBuilder<
                                            LiveStreamBloc,
                                            LiveStreamState
                                          >(
                                            builder: (context, liveState) {
                                              final viewers =
                                                  liveState
                                                      is LiveStreamStreaming
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
                                              final gifts =
                                                  giftState is GiftLoaded
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
                                                diamonCount:
                                                    AppUtils.formatNumber(
                                                      diamondTotal,
                                                    ),
                                                starCount:
                                                    AppUtils.formatNumber(0),
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
                                            final messages =
                                                chatState is ChatLoaded
                                                ? chatState.messages
                                                : <ChatModel>[];
                                            final callState = context
                                                .watch<CallRequestBloc>()
                                                .state;
                                            final isCallingNow =
                                                callState
                                                    is CallRequestLoaded &&
                                                callState
                                                    .activeBroadcasters
                                                    .isNotEmpty;
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
                                                    print(
                                                      "Send message pressed",
                                                    );
                                                    _emitMessageToSocket(
                                                      message,
                                                    );
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
                                                final liveState = context
                                                    .read<LiveStreamBloc>()
                                                    .state;
                                                final viewers =
                                                    liveState
                                                        is LiveStreamStreaming
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
                                            BlocBuilder<
                                              LiveStreamBloc,
                                              LiveStreamState
                                            >(
                                              builder: (context, liveState) {
                                                final isMuted =
                                                    liveState
                                                        is LiveStreamStreaming
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
                                                final audioCallerCount =
                                                    sessionState
                                                        .audioCallerUids
                                                        .length;
                                                if (audioCallerCount > 0) {
                                                  _showSnackBar(
                                                    '🎤 $audioCallerCount audio caller${audioCallerCount > 1 ? 's' : ''} connected',
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
                                                    outerContext
                                                        .read<
                                                          CallRequestBloc
                                                        >();

                                                showModalBottomSheet(
                                                  context: outerContext,
                                                  useRootNavigator: false,
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (sheetContext) {
                                                    return BlocProvider.value(
                                                      value: callRequestBloc,
                                                      child:
                                                          BlocBuilder<
                                                            CallRequestBloc,
                                                            CallRequestState
                                                          >(
                                                            builder:
                                                                (
                                                                  context,
                                                                  callRequestState,
                                                                ) {
                                                                  final pendingRequests =
                                                                      callRequestState
                                                                          is CallRequestLoaded
                                                                      ? callRequestState
                                                                            .pendingRequests
                                                                      : <
                                                                          CallRequestModel
                                                                        >[];
                                                                  final activeBroadcasters =
                                                                      callRequestState
                                                                          is CallRequestLoaded
                                                                      ? callRequestState
                                                                            .activeBroadcasters
                                                                      : <
                                                                          BroadcasterModel
                                                                        >[];

                                                                  // ✅ Filter out host from activeBroadcasters for call management display
                                                                  final hostId =
                                                                      isHost
                                                                      ? userId
                                                                      : widget
                                                                            .hostUserId;
                                                                  final filteredBroadcasters = activeBroadcasters
                                                                      .where(
                                                                        (b) =>
                                                                            b.id !=
                                                                                hostId &&
                                                                            b.id !=
                                                                                widget.hostUserId &&
                                                                            !(isHost &&
                                                                                b.id ==
                                                                                    userId),
                                                                      )
                                                                      .toList();

                                                                  return CallManageBottomSheet(
                                                                    onAcceptCall: (userId) {
                                                                      debugPrint(
                                                                        "Accepting call request from $userId",
                                                                      );
                                                                      callRequestBloc.add(
                                                                        AcceptCallRequest(
                                                                          userId:
                                                                              userId,
                                                                          roomId:
                                                                              _currentRoomId ??
                                                                              '',
                                                                        ),
                                                                      );
                                                                    },
                                                                    onRejectCall: (userId) {
                                                                      debugPrint(
                                                                        "Rejecting call request from $userId",
                                                                      );
                                                                      callRequestBloc.add(
                                                                        RejectCallRequest(
                                                                          userId:
                                                                              userId,
                                                                          roomId:
                                                                              _currentRoomId ??
                                                                              '',
                                                                        ),
                                                                      );
                                                                    },
                                                                    onKickUser: (userId) {
                                                                      callRequestBloc.add(
                                                                        RemoveBroadcaster(
                                                                          userId:
                                                                              userId,
                                                                          roomId:
                                                                              _currentRoomId ??
                                                                              '',
                                                                        ),
                                                                      );
                                                                      debugPrint(
                                                                        "Kicking user $userId from call",
                                                                      );
                                                                    },
                                                                    callers:
                                                                        pendingRequests,
                                                                    inCallList:
                                                                        filteredBroadcasters,
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
                                                final liveState = context
                                                    .read<LiveStreamBloc>()
                                                    .state;
                                                final streamDuration =
                                                    liveState
                                                        is LiveStreamStreaming
                                                    ? liveState.duration
                                                    : Duration.zero;

                                                showGameBottomSheet(
                                                  context,
                                                  userId: userId,
                                                  isHost: isHost,
                                                  streamDuration:
                                                      streamDuration,
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
                                                    print(
                                                      "Send message pressed",
                                                    );
                                                    _emitMessageToSocket(
                                                      message,
                                                    );
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
                                                final liveState = context
                                                    .read<LiveStreamBloc>()
                                                    .state;
                                                final viewers =
                                                    liveState
                                                        is LiveStreamStreaming
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
                                                final liveState = context
                                                    .read<LiveStreamBloc>()
                                                    .state;
                                                final streamDuration =
                                                    liveState
                                                        is LiveStreamStreaming
                                                    ? liveState.duration
                                                    : Duration.zero;

                                                showGameBottomSheet(
                                                  context,
                                                  userId: userId,
                                                  streamDuration:
                                                      streamDuration,
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
                                                final liveState = context
                                                    .read<LiveStreamBloc>()
                                                    .state;
                                                final isMuted =
                                                    liveState
                                                        is LiveStreamStreaming
                                                    ? !liveState.isMicEnabled
                                                    : true;
                                                final streamDuration =
                                                    liveState
                                                        is LiveStreamStreaming
                                                    ? liveState.duration
                                                    : Duration.zero;
                                                final moderationState = context
                                                    .read<ModerationBloc>()
                                                    .state;
                                                showMenuBottomSheet(
                                                  context,
                                                  userId: userId,
                                                  isHost: isHost,
                                                  isMuted: isMuted,
                                                  isAdminMuted:
                                                      _isCurrentUserMuted(
                                                        moderationState,
                                                      ),
                                                  onToggleMute: _toggleMute,
                                                  streamDuration:
                                                      streamDuration,
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
                          final moderationState = context
                              .watch<ModerationBloc>()
                              .state;
                          final hostId = isHost ? userId : widget.hostUserId;
                          final broadcasters = callState is CallRequestLoaded
                              ? callState.activeBroadcasters
                              : const <BroadcasterModel>[];

                          final hostIdentifiers = <String>{
                            if (hostId != null) hostId,
                            if (widget.hostUserId != null) widget.hostUserId!,
                            if (isHost && sessionState.userId != null)
                              sessionState.userId!,
                          };

                          final displayBroadcasters = broadcasters
                              .where((b) => !hostIdentifiers.contains(b.id))
                              .toList();

                          WhoAmI resolveRole(String broadcasterId) {
                            final authState = context.read<AuthBloc>().state;
                            final currentUserId = authState is AuthAuthenticated
                                ? authState.user.id
                                : userId;

                            if (_isCurrentUserAdmin(moderationState)) {
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
                          final callRequestBloc = context
                              .read<CallRequestBloc>();

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
                                  _showSnackBar(
                                    '👑 Set as admin',
                                    Colors.green,
                                  );
                                },
                                onRemoveAdmin: (id) {
                                  _removeAdmin(id);
                                  _showSnackBar(
                                    '👤 Admin removed',
                                    Colors.orange,
                                  );
                                },
                                adminModels: moderationState.adminList,
                                onMuteUser: (id) {
                                  _muteUser(id);
                                  _showSnackBar('🔇 User muted', Colors.orange);
                                },
                                onKickOut: (id) {
                                  _banUser(id);
                                  _showSnackBar(
                                    '👢 User kicked out',
                                    Colors.red,
                                  );
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

                            final isAudioCaller = sessionState.isAudioCaller;
                            final isJoiningRequestPending =
                                !isAudioCaller &&
                                callState is CallRequestLoaded &&
                                userId != null &&
                                callState.pendingRequests.any(
                                  (request) => request.userId == userId,
                                );
                            // ✅ Check against actual displayBroadcasters count (already filtered, audio callers only)
                            final canJoinAudioCall =
                                !sessionState.isHost &&
                                !isAudioCaller &&
                                displayBroadcasters.length <
                                    LiveSessionState.maxAudioCallers &&
                                !sessionState.isJoiningAudioCaller;
                            final maxAudioCallers =
                                LiveSessionState.maxAudioCallers;

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
                                    '🎤 ${displayBroadcasters.length}/$maxAudioCallers',
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
                                  if (isJoiningRequestPending) {
                                    _showSnackBar(
                                      '🎤 Please wait...',
                                      Colors.orange,
                                    );
                                    return;
                                  }

                                  if (isAudioCaller) {
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

                                    if (!canJoinAudioCall) {
                                      _showSnackBar(
                                        '🎤 Audio call is full',
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
                                    color: isJoiningRequestPending
                                        ? Colors.grey
                                        : isAudioCaller
                                        ? Colors.orange
                                        : canJoinAudioCall
                                        ? const Color(0xFFFEB86F)
                                        : const Color(0xFFFEB86F),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      isJoiningRequestPending
                                          ? SizedBox(
                                              width: 40.w,
                                              height: 40.h,
                                              child:
                                                  const CircularProgressIndicator(
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
                                        isJoiningRequestPending
                                            ? 'Joining'
                                            : isAudioCaller
                                            ? 'Leave'
                                            : canJoinAudioCall
                                            ? _getAudioCallerText(sessionState)
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
  Widget _buildVideoView(LiveSessionState sessionState) {
    final isInitializing =
        sessionState.status == LiveSessionStatus.initializingAgora;

    if (isInitializing) {
      debugPrint('📺 [VIDEO] Initializing Agora engine...');
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    // ✅ CRITICAL FIX: Only show loading for hosts during connection
    // Viewers should show video view once they join, even if waiting for remote video
    if (sessionState.isVideoConnecting &&
        !sessionState.isVideoReady &&
        sessionState.isHost) {
      debugPrint('📺 [VIDEO] Host connecting...');
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    if (sessionState.engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    if (isHost) {
      return _buildHostMultiView(sessionState);
    }
    return _buildAudienceMultiView(sessionState);
  }

  /// Build multi-broadcaster view for host
  Widget _buildHostMultiView(LiveSessionState sessionState) {
    final allVideoBroadcasters = <int>[
      if (sessionState.localUserJoined) 0,
      ...sessionState.videoCallerUids,
    ];

    if (allVideoBroadcasters.isEmpty || !sessionState.localUserJoined) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return _buildMultiVideoLayout(
      sessionState,
      allVideoBroadcasters,
      isHostView: true,
    );
  }

  /// Build multi-broadcaster view for audience
  Widget _buildAudienceMultiView(LiveSessionState sessionState) {
    // ✅ ARCHITECTURE: In this app, ONLY the HOST can have video
    // Audio callers and viewers are always audio/watch-only

    // ✅ CRITICAL FIX: Display video from the user who is actually sending video
    // Use videoCallerUids instead of remoteUsers because the first remote user
    // might not be the one broadcasting video (race condition with onUserJoined vs onRemoteVideoStateChanged)
    final hostVideoUid = sessionState.videoCallerUids.isNotEmpty
        ? sessionState.videoCallerUids.first
        : null;

    // ✅ FIX: Show video view once joined, even if waiting for remoteUsers callback
    // remoteUsers might be empty initially due to race condition with onUserJoined
    // As long as localUserJoined=true, we should show video view (it will display host when they appear)
    final shouldShowVideo = sessionState.localUserJoined;

    if (!shouldShowVideo) {
      debugPrint('📺 [AUDIENCE] User not yet joined channel...');
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    debugPrint(
      '📺 [AUDIENCE] Showing video (hostUid=${hostVideoUid ?? "waiting"}, total_remoteUsers=${sessionState.remoteUsers.length}, videoCallers=${sessionState.videoCallerUids.length})',
    );

    // ✅ If hostVideoUid is null, show loading; otherwise show the video
    if (hostVideoUid == null) {
      return Stack(
        children: [
          Container(color: Colors.black),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ],
      );
    }

    return _buildSingleVideoView(sessionState, hostVideoUid, isHostView: false);
  }

  /// Build dynamic multi-video layout based on number of broadcasters
  Widget _buildMultiVideoLayout(
    LiveSessionState sessionState,
    List<int> broadcasterUids, {
    required bool isHostView,
  }) {
    // ✅ Display the first broadcaster (prioritized by video capability)
    final displayUid = isHost
        ? 0
        : (broadcasterUids.isNotEmpty ? broadcasterUids.first : 0);

    return _buildSingleVideoView(
      sessionState,
      displayUid,
      isHostView: isHostView,
    );
  }

  /// Single broadcaster view with video readiness checks
  Widget _buildSingleVideoView(
    LiveSessionState sessionState,
    int uid, {
    required bool isHostView,
  }) {
    final engine = sessionState.engine;
    if (engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    if (uid == 0) {
      return Stack(
        children: [
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
          if (!sessionState.isLocalVideoReady && isHost)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      );
    }

    final shouldShowVideoLoading =
        !sessionState.isVideoReady && !isHost && !isHostView;

    debugPrint(
      '🎥 [VIDEO] Rendering remote video: uid=$uid, shouldShowLoading=$shouldShowVideoLoading, isVideoReady=${sessionState.isVideoReady}, isHost=$isHost, isHostView=$isHostView',
    );

    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(uid: uid),
              connection: RtcConnection(
                channelId: sessionState.currentRoomId ?? roomId,
              ),
            ),
          ),
        ),
        if (shouldShowVideoLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.8),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    debugPrint("🧹 Disposing video live screen...");

    _titleController.dispose();
    _giftAnimationTimer?.cancel();

    _knownPendingRequestIds.clear();
    _knownBroadcasterIds.clear();
    _chatMessages.clear();

    debugPrint("✅ Video live screen disposed");
    super.dispose();
  }
}
