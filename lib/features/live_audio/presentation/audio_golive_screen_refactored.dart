import 'dart:async';
import 'package:dlstarlive/features/live/presentation/widgets/animated_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:dlstarlive/core/network/api_service.dart';
import 'package:dlstarlive/core/utils/permission_helper.dart';
import 'package:dlstarlive/routing/app_router.dart';

import 'package:dlstarlive/features/live/presentation/component/agora_token_service.dart';
import 'package:dlstarlive/features/live/presentation/component/custom_live_button.dart';
import 'package:dlstarlive/features/live/presentation/component/game_bottomsheet.dart';
import 'package:dlstarlive/features/live/presentation/component/menu_bottom_sheet.dart';

import '../../../core/auth/auth_bloc.dart';
import '../data/models/audio_member_model.dart';
import '../data/models/audio_room_details.dart';
// import '../../live/presentation/component/active_viwers.dart';
import '../../live/presentation/component/end_stream_overlay.dart';
import '../../live/presentation/component/host_info.dart';
import '../../live/presentation/component/send_message_buttonsheet.dart';
import 'bloc/audio_room_bloc.dart';
import 'bloc/audio_room_event.dart';
import 'bloc/audio_room_state.dart';
import 'widgets/chat_widget.dart';
import 'widgets/joined_member_page.dart';
import 'widgets/seat_widget.dart';

class AudioGoLiveScreenRefactored extends StatefulWidget {
  final String? roomId;
  final String? hostName;
  final String? hostUserId;
  final String? hostAvatar;
  final List<AudioMember> existingViewers;
  final int hostCoins;
  final AudioRoomDetails? roomData; // Add room data to load initial state
  final int numberOfSeats; // Number of seats in the audio room
  final String roomTitle; // Title of the audio room
  final bool isCreatingRoom; // New flag to distinguish between creating and joining
  const AudioGoLiveScreenRefactored({
    super.key,
    this.roomId,
    this.hostName,
    this.hostUserId,
    this.hostAvatar,
    this.existingViewers = const [],
    this.hostCoins = 0,
    this.roomData, // Optional room data for existing rooms
    this.numberOfSeats = 6, // Default to 6 seats
    this.roomTitle = 'Audio Room', // Default title
    this.isCreatingRoom = false, // Default to joining (safer)
  });

  @override
  State<AudioGoLiveScreenRefactored> createState() => _AudioGoLiveScreenRefactoredState();
}

class _AudioGoLiveScreenRefactoredState extends State<AudioGoLiveScreenRefactored> {
  // User data
  String userName = "You";
  String? userId;
  double? userCoins = 0;
  String userImageUrl = "https://thispersondoesnotexist.com/";
  String userProfileFrame = "assets/images/general/profile_frame.png";

  // Agora SDK variables
  late final RtcEngine _engine;
  final ApiService _apiService = ApiService.instance;
  late final AudioRoomBloc _audioRoomBloc;
  Timer? _reconnectTimer;

  void _uiLog(String message) {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$cyan[AUDIO_ROOM] : UI - $reset $message\n');
    }
  }

  void _dispatchRoomEventsAfterConnection(BuildContext context) {
    final uid = userId;
    if (uid == null) return;

    // Use the explicit flag instead of inferring from roomId
    final isCreatingRoom = widget.isCreatingRoom;
    _uiLog(
      "🎯 Dispatching room events after connection - isCreatingRoom: $isCreatingRoom, roomId: '${widget.roomId}', hasRoomData: ${widget.roomData != null}, uid: $uid",
    );

    if (isCreatingRoom) {
      _uiLog("🏗️ Creating new room with title: ${widget.roomTitle}, seats: ${widget.numberOfSeats}");

      // Verify userId is not null or empty
      if (uid.isEmpty) {
        _uiLog("❌ Cannot create room - userId is empty");
        _showSnackBar('Cannot create room - user ID is missing', Colors.red);
        return;
      }

      context.read<AudioRoomBloc>().add(
        CreateRoomEvent(
          roomId: uid, // User's ID becomes the room ID
          roomTitle: widget.roomTitle,
          numberOfSeats: widget.numberOfSeats,
        ),
      );
    } else if (widget.roomId != null && widget.roomId!.isNotEmpty) {
      // If joining existing room and we have room data, initialize with it
      if (widget.roomData != null) {
        _uiLog(
          "📦 Initializing with existing room data - Host: ${widget.roomData!.hostDetails.name}, Members: ${widget.roomData!.membersDetails.length}, RoomId: ${widget.roomData!.roomId}",
        );
        // Initialize Bloc with existing room data
        final isHost = widget.roomData!.hostDetails.id == uid;
        _uiLog("👑 User is host of existing room: $isHost");
        context.read<AudioRoomBloc>().add(InitializeWithRoomDataEvent(roomData: widget.roomData!, isHost: isHost));
      } else {
        _uiLog("🔗 Joining room without initial data: ${widget.roomId}");
        // Join room normally
        context.read<AudioRoomBloc>().add(JoinRoomEvent(roomId: widget.roomId!));
      }
    } else {
      _uiLog("❌ Invalid state - not creating room and no valid roomId provided");
    }
  }

  // Add room data initialization logic like the original
  void _initializeFromRoomData() {
    _uiLog("🎯 _initializeFromRoomData called - widget.roomData is null: ${widget.roomData == null}");
    if (widget.roomData != null) {
      final roomData = widget.roomData!;
      _uiLog(
        "📦 Initializing with room data - Host: ${roomData.hostDetails.name}, Members: ${roomData.membersDetails.length}, RoomId: ${roomData.roomId}",
      );

      // Determine if current user is the host
      if (userId != null && roomData.hostDetails.id == userId) {
        _uiLog("👑 User is the host of this room");
      } else {
        _uiLog("👤 User is joining as viewer");
      }

      _uiLog("✅ Successfully initialized from existing room data");
    } else {
      _uiLog("❌ No room data available to initialize from");
    }
  }

  @override
  void initState() {
    super.initState();
    _audioRoomBloc = context.read<AudioRoomBloc>();

    // Get user ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
      userName = authState.user.name;

      // Connect to socket first
      _connectToSocket();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndInitialize();
    });
  }

  void _connectToSocket() {
    if (userId != null && userId!.isNotEmpty) {
      _uiLog("🔌 Connecting to audio socket with userId: $userId");
      context.read<AudioRoomBloc>().add(ConnectToSocket(userId: userId!));
    } else {
      _uiLog("❌ Cannot connect to socket - userId is null or empty");
    }
  }

  @override
  void didUpdateWidget(covariant AudioGoLiveScreenRefactored oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomData != widget.roomData) {
      _initializeFromRoomData();
      setState(() {});
    }
  }

  Future<void> _loadUidAndInitialize() async {
    final state = context.read<AuthBloc>().state;
    final String? uid = state is AuthAuthenticated ? state.user.id : null;

    if (uid != null && uid.isNotEmpty) {
      setState(() {
        userId = uid;
      });

      // Initialize from room data after userId is set (only for joining existing rooms)
      if (widget.roomData != null) {
        _initializeFromRoomData();
      }

      // Initialize Agora
      await initAgora();

      // Connect to socket via Bloc
      if (!mounted) return;
      context.read<AudioRoomBloc>().add(ConnectToSocket(userId: uid));
    }
  }

  // Initialize Agora for audio room
  Future<void> initAgora() async {
    try {
      // Check permissions
      bool hasPermissions = await PermissionHelper.hasAudioStreamPermissions();
      if (!hasPermissions) {
        bool granted = await PermissionHelper.requestAudioStreamPermissions();
        if (!granted) {
          _showSnackBar('❌ Microphone permission required', Colors.red);
          return;
        }
      }

      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(
        RtcEngineContext(
          appId: dotenv.env['AGORA_APP_ID'] ?? '',
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Set client role based on current state
      final blocState = context.read<AudioRoomBloc>().state;
      final isHost = blocState is AudioRoomLoaded ? blocState.isHost : false;
      await _engine.setClientRole(
        role: isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
      );

      // Audio-only setup - no video
      await _engine.enableAudio();
      await _engine.disableVideo();

      // Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _uiLog("Joined audio channel: ${connection.channelId}");
            // Start timer via Bloc
            context.read<AudioRoomBloc>().add(UpdateStreamDurationEvent());
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            _uiLog("User $remoteUid joined audio channel");
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _uiLog("User $remoteUid left audio channel");
          },
          onRemoteAudioStateChanged:
              (
                RtcConnection connection,
                int remoteUid,
                RemoteAudioState state,
                RemoteAudioStateReason reason,
                int elapsed,
              ) {
                // Handle audio state changes if needed
              },
        ),
      );

      // Join channel if not host (host joins after room creation)
      final currentState = context.read<AudioRoomBloc>().state;
      if (currentState is AudioRoomLoaded && !currentState.isHost && currentState.currentRoomId != null) {
        await _joinChannelWithDynamicToken(currentState.currentRoomId!);
      }
    } catch (e) {
      _uiLog('❌ Error initializing Agora: $e');
      _showSnackBar('❌ Failed to initialize audio', Colors.red);
    }
  }

  // Generate token and join channel
  Future<void> _joinChannelWithDynamicToken(String roomId) async {
    // Validate roomId before attempting to join
    if (roomId.isEmpty) {
      _uiLog("❌ Cannot join Agora channel with empty roomId");
      return;
    }
    _uiLog("🎯 Joining Agora channel with roomId: '$roomId'");
    try {
      final currentState = context.read<AudioRoomBloc>().state;
      final isHost = currentState is AudioRoomLoaded ? currentState.isHost : false;

      final result = await AgoraTokenService.getRtcToken(
        channelName: roomId,
        role: isHost ? 'publisher' : 'subscriber',
      );

      if (result.token.isNotEmpty) {
        await _engine.joinChannel(
          token: result.token,
          channelId: roomId,
          uid: 0,
          options: ChannelMediaOptions(
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
            clientRoleType: isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
            // Audio-only settings
            publishMicrophoneTrack: true,
            publishCameraTrack: false, // Disable camera
            autoSubscribeAudio: true,
            autoSubscribeVideo: false, // Don't subscribe to video
          ),
        );
        _uiLog("✅ Successfully joined Agora channel: $roomId");
      } else {
        _uiLog("❌ Failed to get Agora token for roomId: $roomId");
      }
    } catch (e) {
      _uiLog('Error joining channel: $e');
    }
  }

  void _emitMessageToSocket(String message) {
    _uiLog("Emitting message to socket: $message");
    final currentState = context.read<AudioRoomBloc>().state;
    if (message.isNotEmpty && currentState is AudioRoomLoaded && currentState.currentRoomId != null) {
      context.read<AudioRoomBloc>().add(SendMessageEvent(roomId: currentState.currentRoomId!, message: message));
    }
  }

  void _takeSeat(String seatId) {
    final currentState = context.read<AudioRoomBloc>().state;
    if (currentState is AudioRoomLoaded &&
        currentState.currentRoomId != null &&
        !currentState.isHost &&
        userId != null) {
      context.read<AudioRoomBloc>().add(
        JoinSeatEvent(roomId: currentState.currentRoomId!, seatKey: seatId, targetId: userId!),
      );
    }
  }

  void _leaveSeat(String seatId) {
    final currentState = context.read<AudioRoomBloc>().state;
    if (currentState is AudioRoomLoaded && currentState.currentRoomId != null && userId != null) {
      context.read<AudioRoomBloc>().add(
        LeaveSeatEvent(roomId: currentState.currentRoomId!, seatKey: seatId, targetId: userId!),
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    // IMPORTANT: Check if widget is still mounted before showing SnackBar
    if (!mounted) {
      debugPrint("⚠️ Attempted to show SnackBar but widget is not mounted: $message");
      return;
    }

    // Get a safe reference to the ScaffoldMessenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Now safely show the SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        scaffoldMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
          );
      }
    });
  }

  void _handleHostDisconnection(String reason) {
    if (!mounted) return;
    _uiLog("🚨 $reason - Exiting audio room...");
    _showSnackBar('📱 $reason', Colors.red);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // Reset Bloc state when user navigates away
  void _resetBlocState() {
    _uiLog("Resetting Bloc state for new room creation/joining");

    // First disconnect socket using stored bloc reference
    _audioRoomBloc.add(DisconnectFromSocket());

    // Then after a short delay, reconnect socket with current user ID
    // Store the timer so we can cancel it if needed
    Timer? reconnectTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted && userId != null) {
        _uiLog("Reconnecting socket after reset");
        _audioRoomBloc.add(ConnectToSocket(userId: userId!));
      }
    });

    // Store the timer in a field so it can be cancelled in dispose if needed
    _reconnectTimer = reconnectTimer;
  }

  void _toggleMute() {
    context.read<AudioRoomBloc>().add(ToggleMuteEvent());
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _playAnimation({String? animationUrl, String? title, String? subtitle}) {
    context.read<AudioRoomBloc>().add(PlayAnimationEvent(animationUrl: animationUrl, title: title, subtitle: subtitle));
  }

  // End live stream
  void _endLiveStream() async {
    try {
      final currentState = context.read<AudioRoomBloc>().state;
      final isHost = currentState is AudioRoomLoaded ? currentState.isHost : false;

      if (isHost) {
        // If host, delete the room
        if (currentState is AudioRoomLoaded && currentState.currentRoomId != null) {
          context.read<AudioRoomBloc>().add(DeleteRoomEvent(roomId: currentState.currentRoomId!));
        }
      } else {
        // If viewer, leave the room
        if (currentState is AudioRoomLoaded && currentState.currentRoomId != null) {
          context.read<AudioRoomBloc>().add(LeaveRoomEvent(roomId: currentState.currentRoomId!));
        }
      }

      // Reset Bloc state for next room creation/joining
      _resetBlocState();

      if (isHost) {
        if (mounted) {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated && currentState is AudioRoomLoaded) {
            context.go(
              AppRoutes.liveSummary,
              extra: {
                'userName': authState.user.name,
                'userId': authState.user.id.substring(0, 6),
                'earnedPoints': 0,
                'newFollowers': 0,
                'totalDuration': _formatDuration(currentState.streamDuration),
                'userAvatar': authState.user.avatar,
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
      _uiLog('Error ending live stream: $e');
      // Reset Bloc state even on error
      _resetBlocState();
      // Still navigate back even if update fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ###################### Widget build - This method is used to build the UI ######################
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioRoomBloc, AudioRoomState>(
      listener: (context, state) {
        // CRITICAL: Check if widget is still mounted before processing ANY state changes
        if (!mounted) {
          debugPrint("⚠️ Ignoring state change because widget is not mounted: ${state.runtimeType}");
          return;
        }

        // Now your existing code is safe to run
        if (state is AudioRoomError) {
          _showSnackBar('❌ ${state.message}', Colors.red);
        }

        if (state is AudioRoomLoaded && state.currentRoomId != null) {
          // Join Agora channel when room is loaded and we have a room ID
          if (state.isHost) {
            // Host joins immediately
            _joinChannelWithDynamicToken(state.currentRoomId!);
          }
        } else if (state is AudioRoomConnected) {
          // Socket connected, now we can dispatch room events
          _dispatchRoomEventsAfterConnection(context);
        } else if (state is AudioRoomClosed) {
          _handleHostDisconnection(state.reason ?? 'Room ended');
        } else if (state is UserBanned) {
          if (state.targetId == userId) {
            _handleHostDisconnection('You have been banned from this room.');
          }
        } else if (state is MessageReceived) {
          // Handle special messages like entry animations
          final message = state.message;
          final String normalizedMessage = message.text.trim().toLowerCase();
          final dynamic entryAnimation = message.equipedStoreItems?['entry'];
          if (normalizedMessage == 'joined the room' && entryAnimation is String && entryAnimation.isNotEmpty) {
            _playAnimation(animationUrl: entryAnimation, title: '${message.name} joined the room');
          }
        } else if (state is AudioRoomError) {
          _showSnackBar('❌ ${state.message}', Colors.red);
        } else if (state is AnimationPlaying) {
          // Animation handled in UI
        }
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          // Always trigger cleanup when back navigation is invoked
          _endLiveStream();
          debugPrint('Back navigation invoked: (cleanup triggered)');
        },
        child: Scaffold(
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is! AuthAuthenticated) {
                return Center(
                  child: Text('Please log in to start live streaming', style: TextStyle(fontSize: 18.sp)),
                );
              } else {
                return BlocBuilder<AudioRoomBloc, AudioRoomState>(
                  builder: (context, roomState) {
                    if (roomState is AudioRoomInitial || roomState is AudioRoomLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (roomState is AudioRoomLoaded) {
                      return Stack(
                        children: [
                          // Background
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/icons/audio_room/audio_room_background.png"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // Main content with seats grid
                          Column(
                            children: [
                              SizedBox(height: 160.h), // Space for top bar
                              SeatWidget(
                                numberOfSeats: widget.numberOfSeats,
                                currentUserId: userId,
                                currentUserName: authState.user.name,
                                currentUserAvatar: authState.user.avatar,
                                hostDetails: roomState.roomData?.hostDetails,
                                premiumSeat: roomState.roomData?.premiumSeat,
                                seatsData: roomState.roomData?.seatsData,
                                onTakeSeat: _takeSeat,
                                onLeaveSeat: _leaveSeat,
                                isHost: roomState.isHost,
                              ),
                              Spacer(),
                            ],
                          ),

                          // Individual UI components (not blocking the entire screen)
                          _buildTopBar(authState, roomState),
                          _buildChatWidget(roomState),
                          _buildBottomButtons(authState, roomState),

                          // Animation layer
                          if (roomState.animationPlaying)
                            AnimatedLayer(
                              gifts: [], // sentGifts,
                              customAnimationUrl: roomState.animationUrl,
                              customTitle: roomState.animationTitle,
                              customSubtitle: roomState.animationSubtitle,
                            ),
                        ],
                      );
                    } else {
                      return Center(
                        child: Text('Failed to load audio room', style: TextStyle(fontSize: 18.sp)),
                      );
                    }
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ###################### Build functions to build UI components ######################
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  Widget _buildTopBar(AuthAuthenticated authState, AudioRoomLoaded roomState) {
    return Positioned(
      top: 30.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        color: Colors.transparent, // Important for hit testing
        child: Column(
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (roomState.isHost)
                  HostInfo(
                    imageUrl: authState.user.avatar ?? "https://thispersondoesnotexist.com/",
                    name: authState.user.name,
                    id: authState.user.id.length >= 4 ? authState.user.id.substring(0, 4) : authState.user.id,
                    hostUserId: authState.user.id,
                    currentUserId: authState.user.id,
                  )
                else
                  HostInfo(
                    imageUrl: widget.hostAvatar ?? "https://thispersondoesnotexist.com/",
                    name: widget.hostName ?? "Host",
                    id: widget.hostUserId != null && widget.hostUserId!.length >= 4
                        ? widget.hostUserId!.substring(0, 4)
                        : widget.hostUserId ?? "Host",
                    hostUserId: widget.hostUserId ?? "",
                    currentUserId: authState.user.id,
                  ),
                Spacer(),
                JoindListenersPage(
                  activeUserList: roomState.listeners,
                  hostUserId: roomState.isHost ? userId : widget.hostUserId,
                  hostName: roomState.isHost ? authState.user.name : widget.hostName,
                  hostAvatar: roomState.isHost ? authState.user.avatar : widget.hostAvatar,
                ),
                // Leave button
                (roomState.isHost)
                    ? GestureDetector(
                        onTap: () {
                          EndStreamOverlay.show(
                            context,
                            onKeepStream: () {
                              _uiLog("Keep stream pressed");
                            },
                            onEndStream: () {
                              _endLiveStream();
                              _uiLog("End stream pressed");
                            },
                          );
                        },
                        child: Image.asset("assets/icons/live_exit_icon.png", height: 50.h),
                      )
                    : InkWell(
                        onTap: () {
                          _endLiveStream();
                          _uiLog("Disconnect pressed");
                        },
                        child: Image.asset("assets/icons/live_exit_icon.png", height: 50.h),
                      ),
              ],
            ),
            SizedBox(height: 10.h),
            // Second row (diamond/star display if needed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your diamond/star widgets here
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatWidget(AudioRoomLoaded roomState) {
    return Positioned(
      left: 20.w,
      bottom: 120.h, // Above the bottom buttons
      child: Container(
        color: Colors.transparent,
        child: AudioChatWidget(messages: roomState.chatMessages),
      ),
    );
  }

  Widget _buildBottomButtons(AuthAuthenticated authState, AudioRoomLoaded roomState) {
    return Positioned(
      bottom: 30.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        color: Colors.transparent,
        child: roomState.isHost
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMessageButton(),
                  CustomLiveButton(
                    iconPath: "assets/icons/gift_user_icon.png",
                    onTap: () {
                      _showSnackBar('🎁 Not implemented yet', Colors.red);
                    },
                  ),
                  CustomLiveButton(
                    iconPath: "assets/icons/emoji_icon.png",
                    onTap: () {
                      _showSnackBar('🎶 Not implemented yet', Colors.red);
                    },
                  ),
                  CustomLiveButton(
                    iconPath: roomState.isMuted ? "assets/icons/mute_icon.png" : "assets/icons/unmute_icon.png",
                    onTap: () {
                      _showSnackBar('🔇 Not implemented yet', Colors.red);
                    },
                  ),
                  CustomLiveButton(
                    iconPath: "assets/icons/call_icon.png",
                    onTap: () {
                      _showSnackBar('📞 Not implemented yet', Colors.red);
                    },
                  ),
                  CustomLiveButton(
                    iconPath: "assets/icons/menu_icon.png",
                    onTap: () {
                      showGameBottomSheet(
                        context,
                        userId: userId,
                        isHost: roomState.isHost,
                        streamDuration: roomState.streamDuration,
                      );
                    },
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMessageButton(),
                  CustomLiveButton(
                    iconPath: "assets/icons/gift_user_icon.png",
                    onTap: () {
                      _showSnackBar('🎁 Not implemented yet', Colors.red);
                      // showGiftBottomSheet(
                      //   context,
                      //   activeViewers: roomState.listeners,
                      //   roomId: roomState.currentRoomId ?? widget.roomId,
                      //   hostUserId: roomState.isHost ? userId : widget.hostUserId,
                      //   hostName: roomState.isHost ? authState.user.name : widget.hostName,
                      //   hostAvatar: roomState.isHost ? authState.user.avatar : widget.hostAvatar,
                      // );
                    },
                    height: 40.h,
                  ),
                  CustomLiveButton(
                    iconPath: "assets/icons/game_user_icon.png",
                    onTap: () {
                      showGameBottomSheet(context, userId: userId, streamDuration: roomState.streamDuration);
                    },
                    height: 40.h,
                  ),
                  CustomLiveButton(iconPath: "assets/icons/share_user_icon.png", onTap: () {}, height: 40.h),
                  CustomLiveButton(
                    iconPath: "assets/icons/menu_icon.png",
                    onTap: () {
                      showMenuBottomSheet(
                        context,
                        userId: userId,
                        isHost: roomState.isHost,
                        isMuted: roomState.isMuted,
                        isAdminMuted: false, // TODO: Implement admin mute logic
                        onToggleMute: _toggleMute,
                      );
                    },
                    height: 40.h,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return InkWell(
      onTap: () {
        showSendMessageBottomSheet(
          context,
          onSendMessage: (message) {
            _uiLog("Send message pressed");
            _emitMessageToSocket(message);
          },
        );
      },
      child: Stack(
        children: [
          Image.asset("assets/icons/message_icon.png", height: 40.h),
          Positioned(
            left: 10.w,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                Image.asset("assets/icons/message_user_icon.png", height: 20.h),
                SizedBox(width: 5.w),
                Text(
                  'Say Hello!',
                  style: TextStyle(color: Colors.white, fontSize: 18.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any pending timer
    _reconnectTimer?.cancel();
    // Reset Bloc state (but don't schedule any new timers)
    _audioRoomBloc.add(DisconnectFromSocket());

    // Dispose Agora engine
    _engine.leaveChannel();
    _engine.release();

    super.dispose();
  }
}
