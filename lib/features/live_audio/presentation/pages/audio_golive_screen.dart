import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:dlstarlive/core/utils/permission_helper.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/utils/app_utils.dart';

// From Video Live
import 'package:dlstarlive/features/live/presentation/widgets/animated_layer.dart';
import 'package:dlstarlive/features/live/presentation/component/agora_token_service.dart';
import 'package:dlstarlive/features/live/presentation/component/custom_live_button.dart';
import 'package:dlstarlive/features/live/presentation/component/end_stream_overlay.dart';
import 'package:dlstarlive/features/live/presentation/component/host_info.dart';
import 'package:dlstarlive/features/live/presentation/component/send_message_buttonsheet.dart';
import 'package:dlstarlive/features/live/presentation/component/diamond_star_status.dart';

// From Audio Live
import 'package:dlstarlive/features/live_audio/data/models/audio_room_details.dart';
import 'package:dlstarlive/features/live_audio/presentation/widgets/show_host_menu_bottomsheet.dart';
import 'package:dlstarlive/features/live_audio/presentation/widgets/joined_member_page.dart';
import 'package:dlstarlive/features/live_audio/presentation/widgets/show_audiance_menu_bottom_sheet.dart';
import 'package:dlstarlive/features/live_audio/presentation/widgets/gift_bottom_sheet.dart';

import '../bloc/audio_room_bloc.dart';
import '../bloc/audio_room_event.dart';
import '../bloc/audio_room_state.dart';
import '../widgets/chat_widget.dart';
import '../widgets/seat_widget.dart';

class AudioGoLiveScreen extends StatefulWidget {
  final bool isHost;
  final String roomId;
  final int numberOfSeats;
  final String roomTitle;
  final AudioRoomDetails? roomDetails;

  const AudioGoLiveScreen({
    super.key,
    required this.isHost,
    required this.roomId,
    required this.numberOfSeats,
    required this.roomTitle,
    this.roomDetails,
  });

  @override
  State<AudioGoLiveScreen> createState() => _AudioGoLiveScreenState();
}

class _AudioGoLiveScreenState extends State<AudioGoLiveScreen> {
  // User data
  String authUserId = "";
  String userName = "You";
  String demoUserImageUrl = "https://thispersondoesnotexist.com/";
  String demoUserProfileFrame = "assets/images/general/profile_frame.png";

  // Agora SDK variables
  late final RtcEngine _engine;
  // final ApiService _apiService = ApiService.instance;
  late final AudioRoomBloc _audioRoomBloc;
  late final AuthBloc _authBloc;
  Timer? _reconnectTimer;
  bool _isAgoraInitialized = false;
  bool _isInitializingAgora = false;
  bool _isJoiningAgoraChannel = false;
  bool _hasJoinedChannel = false;
  bool _hasAttemptedToJoin = false;

  // UI Log
  void _uiLog(String message) {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';
    if (kDebugMode) debugPrint('\n$cyan[AUDIO_ROOM] : UI - $reset $message\n');
  }

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _audioRoomBloc = context.read<AudioRoomBloc>();

    // Get user ID from auth state
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      authUserId = authState.user.id;
      userName = authState.user.name;
      // Connect to socket first
      _connectToAudioSocket();
    } else {
      _uiLog("❌ User is not authenticated");
      _showSnackBar('❌ User is not authenticated', Colors.red);
      context.read<AuthBloc>().add(AuthLogoutEvent());
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndInitialize();
    });
  }

  // void _refreshRoomData() {
  //   final currentState = context.read<AudioRoomBloc>().state;
  //   if (currentState is AudioRoomLoaded && currentState.currentRoomId != null) {
  //     _uiLog("🔄 Refreshing room data for roomId: ${currentState.currentRoomId}");
  //     context.read<AudioRoomBloc>().add(GetRoomDetailsEvent(roomId: currentState.currentRoomId!));
  //   }
  // }

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ################## Socket Connection and Room Initialization ##################
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  void _dispatchRoomEventsAfterConnection(BuildContext context) {
    _uiLog(
      "🎯 Dispatching room events after connection - isHost: ${widget.isHost}, roomId: '${widget.roomId}', uid: $authUserId",
    );

    if (widget.isHost) {
      // Create room
      _uiLog("🏗️ Creating new room with title: ${widget.roomTitle}, seats: ${widget.numberOfSeats}");
      _uiLog("Host's ID: $authUserId");
      _uiLog("Room ID: ${widget.roomId}");

      if (widget.roomDetails != null) {
        // If the room already exists, initialize the state and join immediately.
        _uiLog("✅ Room already exists. Joining room with provided room data.");
        context.read<AudioRoomBloc>().add(
          InitializeWithRoomDataEvent(roomData: widget.roomDetails!, isHost: widget.isHost, userId: authUserId),
        );
      } else {
        // If the room does not exist, create it.
        _uiLog("🏗️ Creating new room with title: ${widget.roomTitle}, seats: ${widget.numberOfSeats}");
        context.read<AudioRoomBloc>().add(
          CreateRoomEvent(roomId: widget.roomId, roomTitle: widget.roomTitle, numberOfSeats: widget.numberOfSeats),
        );
      }
      _hasAttemptedToJoin = true;
    } else {
      // For non-hosts, we first ensure room data is available, then join.
      if (widget.roomDetails != null) {
        // If room data is already provided, initialize the state and join immediately.
        _uiLog("✅ Initializing with provided room data.");
        context.read<AudioRoomBloc>().add(
          InitializeWithRoomDataEvent(roomData: widget.roomDetails!, isHost: widget.isHost, userId: authUserId),
        );
      } else {
        // If room data is not provided, fetch it first.
        // The BlocListener will handle joining after the data is loaded.
        _uiLog("ℹ️ Room details not provided. Fetching from server...");
        context.read<AudioRoomBloc>().add(GetRoomDetailsEvent(roomId: widget.roomId));
      }
    }
  }

  void _connectToAudioSocket() {
    if (widget.roomId.isNotEmpty) {
      _uiLog("🔌 Connecting to audio socket with roomId: ${widget.roomId} , userId: $authUserId");
      context.read<AudioRoomBloc>().add(ConnectToSocket(userId: authUserId));
    } else {
      _uiLog("❌ Cannot connect to socket - roomId is null or empty");
    }
  }

  Future<void> _loadUidAndInitialize() async {
    final state = context.read<AuthBloc>().state;
    final String? uid = state is AuthAuthenticated ? state.user.id : null;

    if (uid != null && uid.isNotEmpty) {
      setState(() => authUserId = uid);

      // Connect to socket via Bloc
      _connectToAudioSocket();

      // Socket connection is handled by the BlocListener, which will then trigger Agora initialization.
    }
  }

  // Initialize Agora for audio room
  Future<void> initAudioAgora() async {
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
          logConfig: LogConfig(filePath: 'agora_rtc_engine.log', level: LogLevel.logLevelNone),
          appId: dotenv.env['AGORA_APP_ID'] ?? '',
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Audio-only setup - no video
      await _engine.enableAudio();
      await _engine.disableVideo();

      // Register event handlers
      _isAgoraInitialized = true;
      _uiLog("✅ Agora engine initialized successfully");

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _uiLog('✅ Successfully joined Agora channel: ${connection.channelId}');
            setState(() {
              _hasJoinedChannel = true;
              _isJoiningAgoraChannel = false;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            _uiLog('❌ Agora Error: $msg');
            setState(() {
              _isJoiningAgoraChannel = false;
            });
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
                _uiLog("Remote audio state changed for user $remoteUid: $state");
              },
        ),
      );
    } catch (e) {
      _uiLog('❌ Error initializing Agora: $e');
      _showSnackBar('❌ Failed to initialize Agora', Colors.red);
    }
  }

  // Update client role to broadcaster
  Future<void> _updateClientRoleToAudience() async {
    _uiLog('🎧 Attempting to update client role to Audience...');
    try {
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      _uiLog('✅ Client role updated to Audience');
    } catch (e) {
      _uiLog('❌ Error updating client role to Audience: $e');
    }
  }

  Future<void> _updateClientRoleToBroadcaster() async {
    _uiLog('👑 Attempting to update client role to Broadcaster...');
    try {
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      _uiLog('✅ Client role updated to Broadcaster');
    } catch (e) {
      _uiLog('❌ Error updating client role to Broadcaster: $e');
    }
  }

  // Generate token and join channel
  Future<void> _joinAudioChannelWithDynamicToken(String roomId) async {
    if (_hasJoinedChannel) {
      _uiLog("⚠️ Already joined channel, skipping...");
      return;
    }
    // Ensure Agora is initialized before joining
    if (!_isAgoraInitialized) {
      _uiLog("⚠️ Agora not initialized. Initializing now...");
      await initAudioAgora();
    }
    // Validate roomId before attempting to join
    if (roomId.isEmpty) {
      _uiLog("❌ Cannot join Agora channel with empty roomId");
      return;
    }

    // Check if socket is connected before proceeding
    final currentState = context.read<AudioRoomBloc>().state;
    if (currentState is! AudioRoomLoaded || !currentState.isConnected) {
      _uiLog("❌ Cannot join Agora channel - socket not connected or room not loaded");
      _showSnackBar('❌ Cannot join Agora channel - connection issue', Colors.red);
      return;
    }

    _uiLog("🎯 Joining Agora channel with roomId: '$roomId'");
    try {
      final isHost = currentState.isHost;

      final result = await AgoraTokenService.getRtcToken(
        channelName: roomId,
        role: isHost ? 'publisher' : 'subscriber',
      );
      _uiLog("✅ Token generated successfully : ${result.token}");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('audio_agora_token', result.token);
      if (result.token.isNotEmpty) {
        final dynamicToken = result.token;
        _uiLog("✅ Token generated successfully : $dynamicToken");

        // Set client role before joining
        final role = isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience;
        await _engine.setClientRole(role: role);
        _uiLog("👑 Setting client role to: $role");

        // _showSnackBar('📡 Joining live stream...', Colors.blue);
        await _engine.joinChannel(
          token: dynamicToken,
          channelId: roomId,
          uid: 0,
          options: ChannelMediaOptions(
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
            clientRoleType: role,
            // Audio-only settings
            publishMicrophoneTrack: true,
            publishCameraTrack: false, // Disable camera
            autoSubscribeAudio: true,
            autoSubscribeVideo: false, // Don't subscribe to video
          ),
        );
        _hasJoinedChannel = true;
        _uiLog("✅ Successfully joined Agora channel: $roomId");
      } else {
        _uiLog("❌ Failed to get Agora token $result");
        _showSnackBar('❌ Failed to get Agora token', Colors.red);
        // Fallback to static token
        await _joinAudioChannelWithStaticToken();
      }
    } catch (e) {
      _uiLog('❌ Error joining Agora channel: $e');
      _hasJoinedChannel = false; // Reset on error to allow retry
      _showSnackBar('❌ Error joining Agora channel', Colors.red);
      // Fallback to static token
      await _joinAudioChannelWithStaticToken();
    }
  }

  Future<void> _joinAudioChannelWithStaticToken() async {
    _uiLog("🎯 Joining Agora channel with static token");
    await _engine.joinChannel(
      token: dotenv.env['AGORA_TOKEN'] ?? '',
      channelId: dotenv.env['DEFAULT_CHANNEL'] ?? 'default_channel',
      uid: 0,
      options: const ChannelMediaOptions(),
    );
    _uiLog("✅ Successfully joined Agora channel: ${dotenv.env['DEFAULT_CHANNEL']}");
    // _showSnackBar('📡 Joining live stream...', Colors.blue);
  }

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ################## Socket Events ##################
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  void _emitMessageToAudioSocket(String message) {
    _uiLog("Emitting message to audio socket: $message");
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
        authUserId.isNotEmpty) {
      context.read<AudioRoomBloc>().add(
        JoinSeatEvent(roomId: currentState.currentRoomId!, seatKey: seatId, targetId: authUserId),
      );
    }
  }

  void _leaveSeat(String seatId) {
    final currentState = context.read<AudioRoomBloc>().state;
    if (currentState is AudioRoomLoaded && currentState.currentRoomId != null && authUserId.isNotEmpty) {
      context.read<AudioRoomBloc>().add(
        LeaveSeatEvent(roomId: currentState.currentRoomId!, seatKey: seatId, targetId: authUserId),
      );
    }
  }

  void _removeUserFromSeat(String seatId, String targetId) {
    final currentState = context.read<AudioRoomBloc>().state;
    if (currentState is AudioRoomLoaded && currentState.currentRoomId != null) {
      context.read<AudioRoomBloc>().add(
        RemoveFromSeatEvent(roomId: currentState.currentRoomId!, seatKey: seatId, targetId: targetId),
      );
    }
  }

  void _toggleMute() {
    context.read<AudioRoomBloc>().add(ToggleMuteEvent());
  }

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ################## Others ##################
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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

  // String _formatDuration(Duration duration) {
  //   String twoDigits(int n) => n.toString().padLeft(2, '0');
  //   String hours = twoDigits(duration.inHours);
  //   String minutes = twoDigits(duration.inMinutes.remainder(60));
  //   String seconds = twoDigits(duration.inSeconds.remainder(60));
  //   return "$hours:$minutes:$seconds";
  // }

  void _endLiveStream() async {
    try {
      final currentState = context.read<AudioRoomBloc>().state;
      final isHost = currentState is AudioRoomLoaded ? currentState.isHost : false;

      if (isHost) {
        // If host, delete the room
        if (currentState.currentRoomId != null) {
          context.read<AudioRoomBloc>().add(DeleteRoomEvent(roomId: currentState.currentRoomId!));
        }
      } else {
        // If viewer, leave the room
        if (currentState is AudioRoomLoaded && currentState.currentRoomId != null) {
          context.read<AudioRoomBloc>().add(LeaveRoomEvent(memberID: authUserId));
        }
      }
      // Close Agora
      await _engine.leaveChannel().then((value) {
        _uiLog("✅ Successfully left Agora channel");
      });

      _hasJoinedChannel = false; // Reset channel joined flag

      // Reset Bloc state for next room creation/joining
      _resetBlocState();

      if (isHost) {
        if (mounted) {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated && currentState.currentRoomId != null) {
            context.go(
              AppRoutes.audioLiveSummary,
              extra: {
                'userName': authState.user.name,
                'userId': authState.user.id.substring(0, 6),
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

  // Reset Bloc state when user navigates away
  void _resetBlocState() {
    _uiLog("Resetting Bloc state for new room creation/joining");

    // First disconnect socket using stored bloc reference
    _audioRoomBloc.add(DisconnectFromSocket());

    // Then after a short delay, reconnect socket with current user ID
    // Store the timer so we can cancel it if needed
    Timer? reconnectTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted && authUserId.isNotEmpty) {
        _uiLog("Reconnecting socket after reset");
        _audioRoomBloc.add(ConnectToSocket(userId: authUserId));
      }
    });

    // Store the timer in a field so it can be cancelled in dispose if needed
    _reconnectTimer = reconnectTimer;
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

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ###################### Widget build - This method is used to build the UI ######################
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @override
  Widget build(BuildContext context) {
    return PopScope(
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
            }
            return BlocConsumer<AudioRoomBloc, AudioRoomState>(
              listenWhen: (previous, current) {
                if (previous is AudioRoomLoaded && current is AudioRoomLoaded) {
                  return previous.isBroadcaster != current.isBroadcaster;
                }
                return true;
              },
              listener: (context, state) {
                // CRITICAL: Check if widget is still mounted before processing ANY state changes
                if (!mounted) {
                  debugPrint("⚠️ Ignoring state change because widget is not mounted: ${state.runtimeType}");
                  return;
                }

                if (state is AudioRoomLoaded) {
                  _uiLog("✅ Room loaded: ${jsonEncode(state.roomData)}");
                  if (state.roomData?.seatsData == null) return;
                  final seatsData = state.roomData!.seatsData;
                  _uiLog("✅ SeatsData: ${jsonEncode(seatsData)}");

                  // If the user is not the host and the room data has just been loaded,
                  // it's time to join the room.
                  if (widget.isHost == false && _hasAttemptedToJoin == false && state.currentRoomId != null) {
                    _hasAttemptedToJoin = true; // Set the flag immediately to prevent re-entry
                    final isAlreadyInRoom = state.listeners.any((member) => member.id == authUserId);
                    if (!isAlreadyInRoom) {
                      _uiLog("✅ Room details fetched. User not in room yet. Now joining room: ${state.currentRoomId}");
                      context.read<AudioRoomBloc>().add(
                        JoinRoomEvent(roomId: state.currentRoomId!, memberID: authUserId),
                      );
                    } else {
                      _uiLog("✅ User is already in the room. No need to join again.");
                    }
                  }
                }

                if (state is AudioRoomLoaded &&
                    state.currentRoomId != null &&
                    !_hasJoinedChannel &&
                    _hasAttemptedToJoin &&
                    !_isJoiningAgoraChannel) {
                  setState(() {
                    _isJoiningAgoraChannel = true;
                  });
                  // Join Agora channel only if we haven't joined already.
                  _uiLog("Attempting to join Agora channel...");
                  _joinAudioChannelWithDynamicToken(state.currentRoomId!);
                } else if (state is AudioRoomConnected) {
                  // Socket connected, initialize Agora, then dispatch room events.
                  if (!_isAgoraInitialized && !_isInitializingAgora) {
                    setState(() {
                      _isInitializingAgora = true;
                    });
                    initAudioAgora().then((_) {
                      if (mounted && _isAgoraInitialized) {
                        _dispatchRoomEventsAfterConnection(context);
                      }
                      setState(() {
                        _isInitializingAgora = false;
                      });
                    });
                  }
                } else if (state is AudioRoomLoaded && state.bannedUsers.contains(authUserId)) {
                  _handleHostDisconnection('You have been banned from this room.');
                } else if (state is AudioRoomLoaded && !state.isHost) {
                  // Only update role for non-hosts based on seat status
                  if (state.isBroadcaster) {
                    _updateClientRoleToBroadcaster();
                  } else {
                    _updateClientRoleToAudience();
                  }
                } else if (state is AudioRoomClosed) {
                  _handleHostDisconnection(state.reason ?? 'Room ended');
                } else if (state is AudioRoomError) {
                  _showSnackBar('❌ ${state.message}', Colors.red);
                } else if (state is AnimationPlaying) {
                  // Animation handled in UI
                }
              },
              builder: (context, roomState) {
                if (roomState is AudioRoomLoaded) {
                  _uiLog("Audio Room Loaded");
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
                            currentUserId: authUserId,
                            currentUserName: authState.user.name,
                            currentUserAvatar: authState.user.avatar,
                            hostDetails: roomState.roomData?.hostDetails,
                            premiumSeat: roomState.roomData?.premiumSeat,
                            seatsData: roomState.roomData?.seatsData,
                            onTakeSeat: _takeSeat,
                            onLeaveSeat: _leaveSeat,
                            onRemoveUserFromSeat: _removeUserFromSeat,
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
                } else if (roomState is AudioRoomError) {
                  _uiLog("Audio Room Error");
                  return Center(child: Text('Failed to load audio room: ${roomState.message}'));
                } else if (roomState is AudioRoomClosed) {
                  _uiLog("Audio Room Closed");
                  return Center(child: Text('Room closed: ${roomState.reason}'));
                } else {
                  _uiLog("Audio Room Loading or Not found");
                  // For AudioRoomInitial, AudioRoomLoading, or any other intermediate state
                  return const Center(child: CircularProgressIndicator());
                }
              },
            );
          },
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
                    imageUrl: roomState.roomData?.hostDetails.avatar ?? "https://thispersondoesnotexist.com/",
                    name: roomState.roomData?.hostDetails.name ?? "Host",
                    id: roomState.roomData?.hostDetails.id ?? "",
                    hostUserId: roomState.roomData?.hostDetails.id ?? "",
                    currentUserId: authState.user.id,
                  ),
                Spacer(),
                JoindListenersPage(
                  activeUserList: roomState.listeners,
                  hostUserId: roomState.roomData?.hostDetails.id,
                  hostName: roomState.roomData?.hostDetails.name,
                  hostAvatar: roomState.roomData?.hostDetails.avatar,
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
                DiamondStarStatus(
                  diamonCount: AppUtils.formatNumber(
                    roomState.roomData?.hostBonus ?? 0,
                  ),
                  starCount: AppUtils.formatNumber(0),
                ),
                // Your diamond/star widgets here
                SizedBox(height: 5.h),
                //add another widget to show the bonus
                // BonusStatus(
                //   bonusCount: AppUtils.formatNumber(
                //     _calculateTotalBonusDiamonds(),
                //   ),
                // ),
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
      bottom: 180.h, // Above the bottom buttons
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
                      // _showSnackBar('🎁 Not implemented yet', Colors.red);
                      showAudioGiftBottomSheet(
                        context,
                        activeViewers: roomState.listeners,
                        roomId: roomState.currentRoomId ?? widget.roomId,
                        hostUserId: roomState.isHost ? authUserId : widget.roomDetails?.hostDetails.id,
                        hostName: roomState.isHost ? authState.user.name : widget.roomDetails?.hostDetails.name,
                        hostAvatar: roomState.isHost ? authState.user.avatar : widget.roomDetails?.hostDetails.avatar,
                      );
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
                    iconPath: "assets/icons/menu_icon.png",
                    onTap: () {
                      showHostMenuBottomSheet(context, userId: authUserId, isHost: roomState.isHost);
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
                      // _showSnackBar('🎁 Not implemented yet', Colors.red);
                      showAudioGiftBottomSheet(
                        context,
                        activeViewers: roomState.listeners,
                        roomId: roomState.currentRoomId ?? widget.roomId,
                        hostUserId: roomState.isHost ? authUserId : widget.roomDetails?.hostDetails.id,
                        hostName: roomState.isHost ? authState.user.name : widget.roomDetails?.hostDetails.name,
                        hostAvatar: roomState.isHost ? authState.user.avatar : widget.roomDetails?.hostDetails.avatar,
                      );
                    },
                    height: 40.h,
                  ),
                  CustomLiveButton(
                    iconPath: "assets/icons/game_user_icon.png",
                    onTap: () {
                      showHostMenuBottomSheet(context, userId: authUserId, isHost: roomState.isHost);
                    },
                    height: 40.h,
                  ),
                  CustomLiveButton(iconPath: "assets/icons/share_user_icon.png", onTap: () {}, height: 40.h),
                  CustomLiveButton(
                    iconPath: "assets/icons/menu_icon.png",
                    onTap: () {
                      showAudianceMenuBottomSheet(
                        context,
                        userId: authUserId,
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
            _emitMessageToAudioSocket(message);
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
