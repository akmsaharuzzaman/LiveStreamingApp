import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:dlstarlive/core/network/api_service.dart';
import 'package:dlstarlive/core/network/models/joined_user_model.dart';
import 'package:dlstarlive/core/utils/permission_helper.dart';
import 'package:dlstarlive/routing/app_router.dart';

import 'package:dlstarlive/features/live/presentation/component/agora_token_service.dart';
import 'package:dlstarlive/features/live/presentation/component/custom_live_button.dart';
import 'package:dlstarlive/features/live/presentation/component/game_bottomsheet.dart';
import 'package:dlstarlive/features/live/presentation/component/gift_bottom_sheet.dart';
import 'package:dlstarlive/features/live/presentation/component/menu_bottom_sheet.dart';
import 'package:dlstarlive/features/live/presentation/widgets/animated_layer.dart';

import '../../../core/auth/auth_bloc.dart';
import '../../../core/network/models/ban_user_model.dart';
import '../models/audio_room_details.dart';
import '../models/chat_model.dart';
import '../models/audio_host_details.dart';
import '../models/seat_model.dart';
import '../service/socket_service_audio.dart';
import '../../live/presentation/component/active_viwers.dart';
import '../../live/presentation/component/end_stream_overlay.dart';
import '../../live/presentation/component/host_info.dart';
import '../../live/presentation/component/send_message_buttonsheet.dart';
import 'widgets/chat_widget.dart';

class AudioGoLiveScreen extends StatefulWidget {
  final String? roomId;
  final String? hostName;
  final String? hostUserId;
  final String? hostAvatar;
  final List<AudioHostDetails> existingViewers;
  final int hostCoins;
  final AudioRoomDetails? roomData; // Add room data to load initial state
  final int numberOfSeats; // Number of seats in the audio room
  final String roomTitle; // Title of the audio room
  const AudioGoLiveScreen({
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
  });

  @override
  State<AudioGoLiveScreen> createState() => _AudioGoLiveScreenState();
}

class _AudioGoLiveScreenState extends State<AudioGoLiveScreen> {
  // User data
  String userName = "You";
  String? userId;
  double? userCoins = 0;
  String userImageUrl = "https://thispersondoesnotexist.com/";
  String userProfileFrame = "assets/images/general/profile_frame.png";

  // Host data
  String hostName = "Host";
  String hostId = "123";
  double hostCoins = 100;
  String hostImageUrl = "https://thispersondoesnotexist.com/";
  String hostProfileFrame = "assets/images/general/profile_frame.png";

  // Special data
  String specialName = "Special";
  String specialId = "123";
  double specialCoins = 100;
  String specialImageUrl = "https://thispersondoesnotexist.com/";
  String specialProfileFrame = "assets/images/general/profile_frame.png";

  // Host Seat data
  SeatModel? hostSeatData;

  // Special Seat data
  SeatModel? specialSeatData;

  // Broadcaster Seat data
  final List<SeatModel> broadcasterSeatData = [];

  // Total seats - initialized from widget
  late int totalSeats = widget.numberOfSeats;

  void _uiLog(String message) {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$cyan[AUDIO_ROOM] : UI - $reset $message\n');
    }
  }

  // Selected seat for context menu
  int? selectedSeatIndex;

  final AudioSocketService _socketService = AudioSocketService.instance;
  String? _currentRoomId;
  bool isHost = true;
  String roomId = "default_channel";
  List<JoinedUserModel> activeViewers = [];
  List<String> broadcasterList = [];
  // List<BroadcasterModel> broadcasterModels = [];
  // List<BroadcasterModel> broadcasterDetails = [];
  // List<GiftModel> sentGifts = [];
  // Banned users
  List<String> bannedUsers = [];
  // Banned user details
  List<BanUserModel> bannedUserModels = [];

  // Live stream timing
  DateTime? _streamStartTime;
  Timer? _durationTimer;
  Duration _streamDuration = Duration.zero;

  // Host activity tracking for viewers
  Timer? _hostActivityTimer;
  bool _animationPlaying = false;
  String? _customAnimationUrl;
  String? _customAnimationTitle;
  String? _customAnimationSubtitle;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _connectionStatusSubscription;

  // Socket subscriptions
  StreamSubscription? _getAllRoomsSubscription; // 1
  StreamSubscription? _audioRoomDetailsSubscription; // 2
  StreamSubscription? _createRoomSubscription; // 3
  StreamSubscription? _closeRoomSubscription; // 4
  StreamSubscription? _joinRoomSubscription; // 5
  StreamSubscription? _leaveRoomSubscription; // 6
  StreamSubscription? _userLeftSubscription; // 7
  StreamSubscription? _joinSeatRequestSubscription; // 8
  StreamSubscription? _leaveSeatRequestSubscription; // 9
  StreamSubscription? _removeFromSeatSubscription; // 10
  StreamSubscription? _sendMessageSubscription; // 11
  StreamSubscription? _errorMessageSubscription; // 12
  StreamSubscription? _muteUnmuteUserSubscription; // 13
  StreamSubscription? _banUserSubscription; // 14
  StreamSubscription? _unbanUserSubscription; // 15

  // Chat messages
  final List<AudioChatModel> _chatMessages = [];

  // Agora SDK variables
  late final RtcEngine _engine;
  bool _muted = false;
  final ApiService _apiService = ApiService.instance;

  @override
  void initState() {
    super.initState();
    _initializeFromRoomData(); // Initialize from existing room data
    // Initialize totalSeats = selected seats + 2 (host + special)
    // e.g., 6 People = 6 + 2 = 8 total seats
    totalSeats = widget.numberOfSeats + 2;
    _initializeSeats();
    // Update seat-1 with host information immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSeatsWithBroadcasters();
      _loadUidAndInitialize();
    });
  }

  /// Initialize state from existing room data (when joining existing live)
  void _initializeFromRoomData() {
    if (widget.roomData != null) {
      final roomData = widget.roomData!;

      // Initialize duration and start time based on existing duration
      if (roomData.duration != null && roomData.duration! > 0) {
        _streamStartTime = DateTime.now().subtract(Duration(seconds: roomData.duration!));
        _streamDuration = Duration(seconds: roomData.duration!);
        _uiLog("🕒 Initialized stream with existing duration: ${roomData.duration}s");
      }

      // Initialize chat messages if any
      if (roomData.messages != null && roomData.messages!.isNotEmpty) {
        _chatMessages.clear();
        for (var messageData in roomData.messages!) {
          if (messageData is Map<String, dynamic>) {
            try {
              final chatMessage = AudioChatModel.fromJson(messageData);
              _chatMessages.add(chatMessage);
            } catch (e) {
              _uiLog("❌ Error parsing message: $e");
              _uiLog("❌ Message data: $messageData");
            }
          }
        }
        _uiLog("💬 Loaded ${_chatMessages.length} existing messages");
      }

      // Initialize members as active viewers (excluding host)
      if (roomData.membersDetails != null && roomData.membersDetails!.isNotEmpty) {
        activeViewers.clear();
        for (var member in roomData.membersDetails!) {
          // Don't add host to viewers list
          if (member.id != roomData.hostDetails?.id) {
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
        _uiLog("👥 Loaded ${activeViewers.length} existing members as viewers");
      }

      // Set room ID if not already set
      if (_currentRoomId == null && roomData.roomId != null) {
        _currentRoomId = roomData.roomId;
        _uiLog("🏠 Set room ID from existing data: ${roomData.roomId}");
      }

      _uiLog("✅ Successfully initialized from existing room data");
    }
  }

  Future<void> _loadUidAndInitialize() async {
    final state = context.read<AuthBloc>().state;
    final String? uid = state is AuthAuthenticated ? state.user.id : null;

    if (uid != null && uid.isNotEmpty) {
      setState(() {
        userId = uid;
      });

      // Initialize Agora and socket
      await initAgora();
      await _initializeSocket();
    }
  }

  Future<void> _initializeSocket() async {
    try {
      final connected = await _socketService.connect(userId!);
      if (connected) {
        _setupSocketListeners();
        if (isHost) {
          await _createRoom();
        } else {
          await _joinRoom(roomId);
        }
      }
    } catch (e) {
      _uiLog('Socket connection error: $e');
    }
  }

  void _setupSocketListeners() {
    // User joined
    _joinSeatRequestSubscription = _socketService.joinSeatRequestStream.listen((data) {
      if (mounted && data.id != widget.hostUserId) {
        if (!activeViewers.any((user) => user.id == data.id)) {
          activeViewers.add(data);
          setState(() {});
        }
      }
    });

    // User left
    _userLeftSubscription = _socketService.userLeftStream.listen((data) {
      if (mounted) {
        activeViewers.removeWhere((user) => user.id == data.id);
        broadcasterList.removeWhere((user) => user == data.id);
        setState(() {});
      }
    });

    // Sent Messages
    _sendMessageSubscription = _socketService.sendMessageStream.listen((data) {
      if (mounted) {
        _uiLog("User sent a message: ${data.text}");
        setState(() {
          _chatMessages.add(data);
          if (_chatMessages.length > 50) {
            _chatMessages.removeAt(0);
          }
        });

        final String normalizedMessage = data.text.trim().toLowerCase();
        final dynamic entryAnimation = data.equipedStoreItems?['entry'];
        if (normalizedMessage == 'joined the room' && entryAnimation is String && entryAnimation.isNotEmpty) {
          _playAnimation(animationUrl: entryAnimation, title: '${data.name} joined the room');
        }
      }
    });

    // Banned users
    _banUserSubscription = _socketService.banUserStream.listen((data) {
      if (mounted) {
        if (data.targetId == userId) {
          _handleHostDisconnection('You have been banned from this room.');
        }
        setState(() {
          bannedUsers.add(data.targetId);
          activeViewers.removeWhere((user) => user.id == data.targetId);
        });
      }
    });

    // Mute user
    _muteUnmuteUserSubscription = _socketService.muteUnmuteUserStream.listen((data) {
      // if (mounted) {
      //   setState(() {
      //     currentMuteState = data;
      //   });
      //   if (_isCurrentUserMuted()) {
      //     _forceMuteCurrentUser();
      //   }
      // }
    });

    // Room closed
    _closeRoomSubscription = _socketService.closeRoomStream.listen((data) {
      if (mounted) {
        _handleHostDisconnection('Audio room ended by host.');
      }
    });
  }

  Future<void> _createRoom() async {
    if (userId == null) return;

    // Create audio room with all required parameters
    final success = await _socketService.createRoom(
      userId!,
      widget.roomTitle,
      targetId: userId,
      numberOfSeats: widget.numberOfSeats,
      seatKey: 'seat-1', // Host always takes seat-1
    );

    if (success) {
      setState(() {
        _currentRoomId = userId;
        roomId = userId!;
      });
      await _joinChannelWithDynamicToken();
    } else {
      _showSnackBar('Failed to create audio room', Colors.red);
    }
  }

  Future<void> _joinRoom(String roomId) async {
    final success = await _socketService.joinRoom(roomId);
    if (success) {
      setState(() {
        _currentRoomId = roomId;
      });
    }
  }

  void _initializeSeats() {
    broadcasterSeatData.clear();
    // Initialize empty seats based on totalSeats configuration
    // Seats will be filled with real broadcaster data from socket
    for (int i = 1; i < totalSeats; i++) {
      broadcasterSeatData.add(
        SeatModel(
          id: 'seat-$i',
          name: null,
          avatar: null,
          isLocked: false,
          // diamonds: null,
        ),
      );
    }
  }

  // Update seats with real broadcaster data
  void _updateSeatsWithBroadcasters() {
    // Get current user info for host seat
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Update host seat (seat 0) with real data
      // if (isHost) {
      //   hostSeatData = SeatModel(
      //     id: 'host',
      //     name: authState.user.name,
      //     avatar: authState.user.avatar,
      //     isLocked: false,
      //     // diamonds: GiftModel.totalDiamondsForHost(sentGifts, userId).toDouble(),
      //     userId: userId,
      //   );
      // } else if (!isHost) {
      // Viewer mode - show host from widget data
      hostSeatData = SeatModel(
        id: 'host',
        name: widget.hostName,
        avatar: widget.hostAvatar,
        isLocked: false,
        // diamonds: widget.hostCoins.toDouble(),
        userId: widget.hostUserId,
      );
      // }

      // Update special seat (seat 1) with real data
      if (specialSeatData != null && broadcasterSeatData.isNotEmpty) {
        specialSeatData = SeatModel(
          id: 'special',
          name: specialName,
          avatar: specialImageUrl,
          isLocked: false,
          // diamonds: specialCoins.toDouble(),
          userId: specialId,
        );
      }

      // Update broadcaster seats
      int seatIndex = 1; // Start after host and special seat
      for (var broadcaster in broadcasterSeatData) {
        broadcasterSeatData[seatIndex] = SeatModel(
          id: 'seat-$seatIndex',
          name: broadcaster.name,
          avatar: broadcaster.avatar,
          isLocked: false,
          // diamonds: GiftModel.totalDiamondsForHost(sentGifts, broadcaster.id).toDouble(),
          userId: broadcaster.id,
        );
        seatIndex++;
      }
    }

    setState(() {});
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

      // Set client role
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
            _startStreamTimer();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            _uiLog("User $remoteUid joined audio channel");
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _uiLog("User $remoteUid left audio channel");
            setState(() {
              // _audioCallerUids.remove(remoteUid);
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
                if (state == RemoteAudioState.remoteAudioStateDecoding) {
                  setState(() {
                    // if (!_audioCallerUids.contains(remoteUid) && _audioCallerUids.length < _maxAudioCallers) {
                    //   _audioCallerUids.add(remoteUid);
                    // }
                  });
                }
              },
        ),
      );

      // Join channel if not host (host joins after room creation)
      if (!isHost) {
        await _joinChannelWithDynamicToken();
      }
    } catch (e) {
      _uiLog('❌ Error initializing Agora: $e');
      _showSnackBar('❌ Failed to initialize audio', Colors.red);
    }
  }

  // Generate token and join channel
  Future<void> _joinChannelWithDynamicToken() async {
    try {
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
      }
    } catch (e) {
      _uiLog('Error joining channel: $e');
    }
  }

  // Socket and helper methods
  void _emitMessageToSocket(String message) {
    _uiLog("Emitting message to socket: $message");
    if (message.isNotEmpty && _currentRoomId != null) {
      _socketService.sendMessage(_currentRoomId!, message);
    }
  }

  bool _isCurrentUserMuted() {
    return false;
    // if (userId == null || currentMuteState == null) return false;
    // return currentMuteState!.allMutedUsersList.contains(userId);
  }

  void _forceMuteCurrentUser() async {
    // if ((isHost || _isAudioCaller) && !_muted) {
    //   try {
    //     await _engine.muteLocalAudioStream(true);
    //     setState(() {
    //       _muted = true;
    //     });
    //     _showSnackBar('🔇 You have been muted by an admin', Colors.red);
    //   } catch (e) {
    //     _uiLog('❌ Error force muting user: $e');
    //   }
    // }
  }

  Future<void> _deleteRoom() async {
    if (_currentRoomId != null) {
      await _socketService.deleteRoom(_currentRoomId!);
      setState(() {
        _currentRoomId = null;
      });
    }
  }

  Future<void> _leaveRoom() async {
    if (_currentRoomId != null) {
      await _socketService.leaveRoom(_currentRoomId!);
      setState(() {
        _currentRoomId = null;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)));
    }
  }

  void _handleHostDisconnection(String reason) {
    if (!mounted) return;
    _uiLog("🚨 $reason - Exiting audio room...");
    _showSnackBar('📱 $reason', Colors.red);
    _stopStreamTimer();
    _hostActivityTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _toggleMute() async {
    // if (isHost || _isAudioCaller) {
    //   _uiLog("Toggle mute");
    //   //Mute/Unmute Audio User
    //   _socketService.muteUnmuteUser(userId!);
    //   await _engine.muteLocalAudioStream(!_muted);
    //   setState(() {
    //     _muted = !_muted;
    //   });
    //   _showSnackBar(_muted ? '🔇 Microphone muted' : '🎤 Microphone unmuted', _muted ? Colors.orange : Colors.green);
    // } else {
    //   _showSnackBar('🎤 Only hosts and speakers can use microphone', Colors.orange);
    // }
  }

  void _startStreamTimer() {
    _streamStartTime ??= DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _streamStartTime != null) {
        setState(() {
          _streamDuration = DateTime.now().difference(_streamStartTime!);
        });

        // if (isHost && _streamDuration.inMinutes >= _bonusIntervalMinutes && !_isCallingBonusAPI) {
        //   int currentMilestone = (_streamDuration.inMinutes ~/ _bonusIntervalMinutes) * _bonusIntervalMinutes;
        //   if (currentMilestone > _lastBonusMilestone) {
        //     _callDailyBonusAPI();
        //   }
        // }
      }
    });
  }

  void _stopStreamTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _playAnimation({String? animationUrl, String? title, String? subtitle}) {
    setState(() {
      _customAnimationUrl = animationUrl;
      _customAnimationTitle = title;
      _customAnimationSubtitle = subtitle;
      _animationPlaying = true;
    });

    Future.delayed(const Duration(seconds: 9), () {
      if (!mounted) return;
      setState(() {
        _animationPlaying = false;
        _customAnimationUrl = null;
        _customAnimationTitle = null;
        _customAnimationSubtitle = null;
      });
    });
  }

  Future<void> _callDailyBonusAPI({bool isStreamEnd = false}) async {
    if (!isHost) return;
    // if (!isStreamEnd && _isCallingBonusAPI) return;
    if (!isStreamEnd) return;

    final totalMinutes = _streamDuration.inMinutes;
    int currentMilestone;

    if (isStreamEnd) {
      currentMilestone = totalMinutes;
    }
    // else {
    //   currentMilestone = (totalMinutes ~/ _bonusIntervalMinutes) * _bonusIntervalMinutes;
    //   if (currentMilestone <= _lastBonusMilestone || currentMilestone < _bonusIntervalMinutes) {
    //     return;
    //   }
    // }

    // if (!isStreamEnd) {
    //   _isCallingBonusAPI = true;
    // }

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/auth/daily-bonus',
        data: {'totalTime': totalMinutes, 'type': 'audio'},
      );

      response.fold(
        (data) {
          if (data['success'] == true && data['result'] != null) {
            final result = data['result'] as Map<String, dynamic>;
            final int bonusDiamonds = result['bonus'] ?? 0;

            if (bonusDiamonds > 0) {
              setState(() {
                // if (!isStreamEnd) {
                //   _lastBonusMilestone = currentMilestone;
                // }
              });

              _showSnackBar('🎉 Streaming bonus: $bonusDiamonds diamonds!', Colors.green);
            }
          }
        },
        (error) {
          _uiLog("❌ Daily bonus API failed: $error");
          setState(() {
            // if (!isStreamEnd) {
            //   _lastBonusMilestone = currentMilestone;
            // }
          });
        },
      );
    } catch (e) {
      _uiLog("❌ Exception calling daily bonus API: $e");
      setState(() {
        // if (!isStreamEnd) {
        //   _lastBonusMilestone = currentMilestone;
        // }
      });
    } finally {
      // if (!isStreamEnd) {
      //   _isCallingBonusAPI = false;
      // }
    }
  }

  // End live stream
  void _endLiveStream() async {
    try {
      // Stop the stream timer
      _stopStreamTimer();

      // Reset audio caller state
      setState(() {
        // _isAudioCaller = false;
        // _audioCallerUids.clear();
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
            // Always call daily bonus API on stream end
            await _callDailyBonusAPI(isStreamEnd: true);

            // Calculate total earned diamonds/coins
            // int earnedDiamonds = GiftModel.totalDiamondsForHost(
            //   sentGifts,
            //   userId!, // Use userId for host
            // );

            // _uiLog("🏆 Host ending live stream - Total earned diamonds: $earnedDiamonds");
            // _uiLog("📊 Total gifts received: ${sentGifts.length}");

            context.go(
              AppRoutes.liveSummary,
              extra: {
                'userName': state.user.name,
                'userId': state.user.id.substring(0, 6),
                'earnedPoints': 0, // Pass actual earned diamonds - earnedDiamonds
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
      _uiLog('Error ending live stream: $e');
      // Still navigate back even if update fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                child: Text('Please log in to start live streaming', style: TextStyle(fontSize: 18.sp)),
              ),
            );
          } else {
            return Scaffold(
              body: Stack(
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
                  SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 160.h), // Space for top bar
                        _buildSeatsGrid(),
                        Spacer(),
                      ],
                    ),
                  ),

                  // Stream options overlay (top bar, chat, bottom buttons)
                  _buildStreamOptions(state),

                  // Animation layer
                  if (_animationPlaying)
                    AnimatedLayer(
                      gifts: [], // sentGifts,
                      customAnimationUrl: _customAnimationUrl,
                      customTitle: _customAnimationTitle,
                      customSubtitle: _customAnimationSubtitle,
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSeatsGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Top row: Host + Special seat (always 2 seats)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildHostOrSpecialSeatItem(broadcasterSeatData[0], true), // Host
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildHostOrSpecialSeatItem(broadcasterSeatData[1], false), // Special seat
              ),
            ],
          ),

          SizedBox(height: 60.h),

          // Remaining seats in grid
          if (broadcasterSeatData.length > 2)
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getGridColumns(),
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 0.h,
                childAspectRatio: 0.8,
              ),
              itemCount: broadcasterSeatData.length - 2, // Exclude host and special seat
              itemBuilder: (context, index) {
                return _buildSeatItem(broadcasterSeatData[index + 2], index + 2);
              },
            ),
        ],
      ),
    );
  }

  // Get number of columns based on total seats
  int _getGridColumns() {
    switch (totalSeats) {
      case 8: // 6 people + 2 (host + special)
        return 3; // 3x2 grid for 6 regular seats
      case 10: // 8 people + 2 (host + special)
        return 4; // 4x2 grid for 8 regular seats
      case 14: // 12 people + 2 (host + special)
        return 4; // 4x3 grid for 12 regular seats
      default:
        return 4; // Default to 4 columns
    }
  }

  Widget _buildHostOrSpecialSeatItem(SeatModel hostSeatData, bool isHost) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Seat circle
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hostSeatData.name != null ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                color: hostSeatData.name != null ? Colors.transparent : Colors.white.withOpacity(0.1),
              ),
              child: ClipOval(
                child: hostSeatData.name != null
                    ? (hostSeatData.avatar != null && hostSeatData.avatar!.isNotEmpty
                          ? Image.network(
                              hostSeatData.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                            ))
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(
                              (!isHost)
                                  ? "assets/icons/audio_room/special_seat.png"
                                  : "assets/icons/audio_room/empty_seat.png",
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
              ),
            ),

            // Crown badge for all occupied seats
            if (hostSeatData.name != null && isHost)
              Positioned(
                top: -25,
                child: Image.asset(
                  "assets/icons/audio_room/crown_badge.png",
                  width: 110.w,
                  height: 110.h,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 110.w,
                      height: 110.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 3),
                      ),
                    );
                  },
                ),
              ),

            // Microphone icon if seat is occupied
            if (hostSeatData.name != null && isHost)
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Icon(Icons.mic, color: Colors.grey[700], size: 14.sp),
                ),
              ),
          ],
        ),

        SizedBox(height: 6.h),

        // User name or seat number
        Text(
          hostSeatData.name ?? (isHost ? "Host Seat" : "Premium Seat"),
          style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSeatItem(SeatModel seat, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSeatIndex = index;
        });
        _showSeatOptions(seat, index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Seat circle
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seat.name != null ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  color: seat.name != null ? Colors.transparent : Colors.white.withOpacity(0.1),
                ),
                child: ClipOval(
                  child: seat.name != null
                      ? (seat.avatar != null && seat.avatar!.isNotEmpty
                            ? Image.network(
                                seat.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[800],
                                child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                              ))
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(
                                seat.isLocked
                                    ? "assets/icons/audio_room/lock_seat.png"
                                    : "assets/icons/audio_room/empty_seat.png",
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                ),
              ),

              // Crown badge for all occupied seats
              if (seat.name != null && !seat.isLocked)
                Positioned(
                  top: -25,
                  child: Image.asset(
                    "assets/icons/audio_room/crown_badge.png",
                    width: 110.w,
                    height: 110.h,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 110.w,
                        height: 110.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 3),
                        ),
                      );
                    },
                  ),
                ),

              // Microphone icon if seat is occupied
              if (seat.name != null && !seat.isLocked)
                Positioned(
                  bottom: -3,
                  right: -3,
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Icon(Icons.mic, color: Colors.grey[700], size: 14.sp),
                  ),
                ),
            ],
          ),

          SizedBox(height: 6.h),

          // User name or seat number
          Text(
            seat.name ?? "Seat ${index + 1}",
            style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSeatOptions(SeatModel seat, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.lock),
                title: Text("Seat Lock"),
                onTap: () {
                  Navigator.pop(context);
                  // Implement seat lock functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.event_seat),
                title: Text("Take Seat"),
                onTap: () {
                  Navigator.pop(context);
                  // Implement take seat functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Manage"),
                onTap: () {
                  Navigator.pop(context);
                  // Implement manage functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreamOptions(AuthAuthenticated state) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // this is the top row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isHost)
                            HostInfo(
                              imageUrl: state.user.avatar ?? "https://thispersondoesnotexist.com/",
                              name: state.user.name,
                              id: state.user.id.substring(0, 4),
                              hostUserId: state.user.id,
                              currentUserId: state.user.id,
                            )
                          else
                            HostInfo(
                              imageUrl: widget.hostAvatar ?? "https://thispersondoesnotexist.com/",
                              name: widget.hostName ?? "Host",
                              id: widget.hostUserId?.substring(0, 4) ?? "Host",
                              hostUserId: widget.hostUserId ?? "",
                              currentUserId: state.user.id,
                            ),
                          Spacer(),
                          // *show the viwers
                          ActiveViewers(
                            activeUserList: activeViewers,
                            hostUserId: isHost ? userId : widget.hostUserId,
                            hostName: isHost ? state.user.name : widget.hostName,
                            hostAvatar: isHost ? state.user.avatar : widget.hostAvatar,
                          ),

                          // * to show the leave button
                          (isHost)
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
                                  child: Image.asset(
                                    "assets/icons/live_exit_icon.png",
                                    height: 50.h,
                                    // width: 40.w,
                                  ),
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

                      //  this is the second row TODO:  diamond and star count display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DiamondStarStatus(
                          //   diamonCount: AppUtils.formatNumber(
                          //     GiftModel.totalDiamondsForHost(
                          //       sentGifts,
                          //       isHost
                          //           ? userId
                          //           : widget.hostUserId, // Use userId for host, widget.hostUserId for viewers
                          //     ),
                          //   ),
                          //   starCount: AppUtils.formatNumber(0),
                          // ),
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
                        child: AudioChatWidget(messages: _chatMessages),
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
                            ),
                            CustomLiveButton(
                              iconPath: "assets/icons/gift_user_icon.png",
                              onTap: () {
                                _showSnackBar('🎁 Not implemented yet', Colors.red);
                                // showGiftBottomSheet(
                                //   context,
                                //   activeViewers: activeViewers,
                                //   roomId: _currentRoomId ?? roomId,
                                //   hostUserId: isHost ? userId : widget.hostUserId,
                                //   hostName: isHost ? state.user.name : widget.hostName,
                                //   hostAvatar: isHost ? state.user.avatar : widget.hostAvatar,
                                // );
                              },
                            ),
                            CustomLiveButton(
                              iconPath: "assets/icons/emoji_icon.png",
                              onTap: () {
                                // _playAnimation();
                                _showSnackBar('🎶 Not implemented yet', Colors.red);
                                // showMusicBottomSheet(context);
                              },
                            ),
                            CustomLiveButton(
                              iconPath: _muted ? "assets/icons/mute_icon.png" : "assets/icons/unmute_icon.png",
                              onTap: () {
                                // _toggleMute();
                                _showSnackBar('🔇 Not implemented yet', Colors.red);
                              },
                            ),
                            CustomLiveButton(
                              iconPath: "assets/icons/call_icon.png",
                              onTap: () {
                                // if (_audioCallerUids.isNotEmpty) {
                                //   _showSnackBar(
                                //     '🎤 ${_audioCallerUids.length} audio caller${_audioCallerUids.length > 1 ? 's' : ''} connected',
                                //     Colors.green,
                                //   );
                                // } else {
                                //   _showSnackBar('📞 Waiting for audio callers to join...', Colors.blue);
                                // }
                                _showSnackBar('📞 Not implemented yet', Colors.red);
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
                                  Image.asset("assets/icons/message_icon.png", height: 40.h),
                                  Positioned(
                                    left: 10,
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
                            ),

                            CustomLiveButton(
                              iconPath: "assets/icons/gift_user_icon.png",
                              onTap: () {
                                showGiftBottomSheet(
                                  context,
                                  activeViewers: activeViewers,
                                  roomId: _currentRoomId ?? roomId,
                                  hostUserId: isHost ? userId : widget.hostUserId,
                                  hostName: isHost ? state.user.name : widget.hostName,
                                  hostAvatar: isHost ? state.user.avatar : widget.hostAvatar,
                                );
                              },
                              height: 40.h,
                            ),

                            CustomLiveButton(
                              iconPath: "assets/icons/game_user_icon.png",
                              onTap: () {
                                showGameBottomSheet(context, userId: userId, streamDuration: _streamDuration);
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
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    _connectionStatusSubscription?.cancel();
    _getAllRoomsSubscription?.cancel(); // 1
    _audioRoomDetailsSubscription?.cancel(); // 2
    _createRoomSubscription?.cancel(); // 3
    _closeRoomSubscription?.cancel(); // 4
    _joinRoomSubscription?.cancel(); // 5
    _leaveRoomSubscription?.cancel(); // 6
    _userLeftSubscription?.cancel(); // 7
    _joinSeatRequestSubscription?.cancel(); // 8
    _leaveSeatRequestSubscription?.cancel(); // 9
    _removeFromSeatSubscription?.cancel(); // 10
    _sendMessageSubscription?.cancel(); // 11
    _errorMessageSubscription?.cancel(); // 12
    _muteUnmuteUserSubscription?.cancel(); // 13
    _banUserSubscription?.cancel(); // 14
    _unbanUserSubscription?.cancel(); // 15

    // Stop timers
    _durationTimer?.cancel();
    _hostActivityTimer?.cancel();

    // Dispose Agora engine
    _engine.leaveChannel();
    _engine.release();

    super.dispose();
  }
}
