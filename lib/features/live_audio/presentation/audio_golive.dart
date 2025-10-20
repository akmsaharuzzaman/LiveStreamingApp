import 'dart:async';
import 'dart:convert';
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
import 'package:dlstarlive/features/live/presentation/widgets/animated_layer.dart';

import '../../../core/auth/auth_bloc.dart';
import '../models/audio_member_model.dart';
import '../models/audio_room_details.dart';
import '../models/chat_model.dart';
import '../service/socket_service_audio.dart';
// import '../../live/presentation/component/active_viwers.dart';
import '../../live/presentation/component/end_stream_overlay.dart';
import '../../live/presentation/component/host_info.dart';
import '../../live/presentation/component/send_message_buttonsheet.dart';
import 'widgets/chat_widget.dart';
import 'widgets/joined_member_page.dart';
import 'widgets/seat_widget.dart';

class AudioGoLiveScreen extends StatefulWidget {
  final String? roomId;
  final String? hostName;
  final String? hostUserId;
  final String? hostAvatar;
  final List<AudioMember> existingViewers;
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

  void _uiLog(String message) {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$cyan[AUDIO_ROOM] : UI - $reset $message\n');
    }
  }

  final AudioSocketService _socketService = AudioSocketService.instance;
  String? _currentRoomId;
  bool isHost = true;
  String roomId = "default_channel";
  List<AudioMember> listeners = [];
  List<String> broadcasterList = [];
  // Room data for seat initialization
  AudioRoomDetails? roomData;
  // List<BroadcasterModel> broadcasterModels = [];
  // List<BroadcasterModel> broadcasterDetails = [];
  // List<GiftModel> sentGifts = [];
  // Banned users
  List<String> bannedUsers = [];
  // Banned user details
  List<AudioMember> bannedUserModels = [];

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
  StreamSubscription? _joinSeatSubscription; // 8
  StreamSubscription? _leaveSeatSubscription; // 9
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
  final bool _muted = false;
  final ApiService _apiService = ApiService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndInitialize();
    });
  }

  @override
  void didUpdateWidget(covariant AudioGoLiveScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomData != widget.roomData) {
      _initializeFromRoomData();
      setState(() {});
    }
  }

  /// Initialize state from existing room data (when joining existing live)
  void _initializeFromRoomData() {
    if (widget.roomData != null) {
      final roomData = widget.roomData!;

      // Store room data for seat widget
      this.roomData = roomData;

      setState(() {}); // Trigger rebuild to update SeatWidget with data

      // Determine if current user is the host
      if (userId != null && roomData.hostDetails.id == userId) {
        isHost = true;
        _uiLog("👑 User is the host of this room");
      } else {
        isHost = false;
        _uiLog("👤 User is joining as viewer");
      }

      // Initialize duration and start time based on existing duration
      if (roomData.duration > 0) {
        _streamStartTime = DateTime.now().subtract(Duration(seconds: roomData.duration));
        _streamDuration = Duration(seconds: roomData.duration);
        _uiLog("🕒 Initialized stream with existing duration: ${roomData.duration}s");
      }

      // Initialize chat messages if any
      if (roomData.messages.isNotEmpty) {
        _chatMessages.clear();
        for (var messageData in roomData.messages) {
          _chatMessages.add(messageData);
        }
        _uiLog("💬 Loaded ${_chatMessages.length} existing messages");
      }

      // Initialize members as active viewers (excluding host)
      if (roomData.membersDetails.isNotEmpty) {
        listeners.clear();
        for (var memberData in roomData.membersDetails) {
          if (memberData is Map<String, dynamic>) {
            try {
              // final member = AudioHostDetails.fromJson(memberData);
              // // Don't add host to viewers list
              // if (member.id != roomData.hostDetails.id) {
              //   final viewer = JoinedUserModel(
              //     id: member.id ?? '',
              //     avatar: member.avatar ?? '',
              //     name: member.name ?? 'Unknown',
              //     uid: member.uid ?? '',
              //     currentLevel: member.currentLevel ?? 0,
              //     currentBackground: member.currentBackground ?? '',
              //     currentTag: member.currentTag ?? '',
              //     diamonds: 0, // Initialize with 0, will be updated from gifts
              //   );
              //   activeViewers.add(viewer);
              // }
            } catch (e) {
              _uiLog("❌ Error parsing member: $e");
              _uiLog("❌ Member data: $memberData");
            }
          }
        }
        _uiLog("👥 Loaded ${listeners.length} existing members as viewers");
      }

      // Set room ID if not already set
      if (_currentRoomId == null && roomData.roomId.isNotEmpty) {
        _currentRoomId = roomData.roomId;
        roomId = roomData.roomId;
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

      // Initialize from room data after userId is set
      _initializeFromRoomData();

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

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ############### Socket listeners - This method is used to listen to the socket events ###############
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  void _setupSocketListeners() {
    // User joined
    _joinRoomSubscription = _socketService.joinRoomStream.listen((data) {
      _uiLog("User joined: ${jsonEncode(data)}");
      if (mounted && data.membersDetails.any((member) => member.id != widget.hostUserId)) {
        AudioMember member = data.membersDetails.firstWhere((member) => member.id != widget.hostUserId);
        if (!listeners.any((user) => user.id == member.id)) {
          listeners.add(member);
          setState(() {});
        }
      }
    });

    // User left
    _userLeftSubscription = _socketService.userLeftStream.listen((data) {
      _uiLog("User left: ${jsonEncode(data)}");
      if (mounted) {
        listeners.removeWhere((user) => user.id == data.id);
        broadcasterList.removeWhere((user) => user == data.id);
        setState(() {});
      }
    });

    // Seat joined
    _joinSeatSubscription = _socketService.joinSeatStream.listen((data) {
      _uiLog("Seat joined: ${jsonEncode(data)}");
      if (mounted && data.member?.id != widget.hostUserId) {
        _uiLog("UI LOG: ${data.seatKey} is updating with user ${data.member?.name}");
        // if (!roomData!.seats.seats![data.seatKey!].any((user) => user.id == data.member?.id)) {
        // setState(() {
        //   roomData!.seatsData.seats![data.seatKey!] = SeatInfo(member: data.member);
        // });
        setState(() {
          // Create a new SeatsData instance to trigger rebuild
          roomData!.seatsData = SeatsData(
            seats: Map<String, SeatInfo>.from(roomData!.seatsData.seats!)
              ..[data.seatKey!] = SeatInfo(member: data.member),
          );
        });
        // }
      }
    });

    // Seat left
    _leaveSeatSubscription = _socketService.leaveSeatStream.listen((data) {
      _uiLog("Seat left: ${jsonEncode(data)}");
      if (mounted) {
        _uiLog("UI LOG: ${data.seatKey} is removing the user");
        setState(() {
          roomData!.seatsData = SeatsData(
            seats: Map<String, SeatInfo>.from(roomData!.seatsData.seats!)
              ..[data.seatKey!] = SeatInfo(member: null),
          );
        });
      }
    });

    // Sent Messages
    _sendMessageSubscription = _socketService.sendMessageStream.listen((data) {
      _uiLog("User sent a message: ${jsonEncode(data)}");
      if (mounted) {
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
      _uiLog("User banned: ${jsonEncode(data)}");
      if (mounted) {
        if (data.targetId == userId) {
          _handleHostDisconnection('You have been banned from this room.');
        }
        setState(() {
          bannedUsers.add(data.targetId);
          listeners.removeWhere((user) => user.id == data.targetId);
        });
      }
    });

    // Mute user
    _muteUnmuteUserSubscription = _socketService.muteUnmuteUserStream.listen((data) {
      _uiLog("User muted: ${jsonEncode(data)}");
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
      _uiLog("Room closed: ${jsonEncode(data)}");
      if (mounted) {
        _handleHostDisconnection('Audio room ended by host.');
      }
    });
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

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ############## Socket room methods - This method is used to send data to the socket ##############
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  Future<void> _createRoom() async {
    if (userId == null) return;

    // Create audio room with all required parameters
    final success = await _socketService.createRoom(userId!, widget.roomTitle, numberOfSeats: widget.numberOfSeats);

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

  Future<void> _leaveRoom() async {
    if (_currentRoomId != null) {
      await _socketService.leaveRoom(_currentRoomId!);
      setState(() {
        _currentRoomId = null;
      });
    }
  }

  Future<void> _deleteRoom() async {
    if (_currentRoomId != null) {
      await _socketService.deleteRoom(_currentRoomId!);
      setState(() {
        _currentRoomId = null;
      });
    }
  }

  void _takeSeat(String seatId) {
    final roomId = _currentRoomId ?? widget.roomId;
    if (roomId != null && !isHost) {
      _socketService.joinSeat(roomId: roomId, seatKey: seatId, targetId: userId!);
    }
  }

  void _leaveSeat(String seatId) async {
    final roomId = _currentRoomId ?? widget.roomId;
    if (roomId != null) {
      _socketService.leaveSeat(roomId: roomId, seatKey: seatId, targetId: userId!);
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
    // int currentMilestone;

    // if (isStreamEnd) {
    //   currentMilestone = totalMinutes;
    // }
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
            // await _callDailyBonusAPI(isStreamEnd: true);

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
        debugPrint(
          'Back navigation invoked: '
          '(cleanup triggered)',
        );
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is! AuthAuthenticated) {
              return Center(
                child: Text('Please log in to start live streaming', style: TextStyle(fontSize: 18.sp)),
              );
            } else {
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
                        currentUserName: state.user.name,
                        currentUserAvatar: state.user.avatar,
                        hostDetails: roomData?.hostDetails,
                        premiumSeat: roomData?.premiumSeat,
                        seatsData: roomData?.seatsData,
                        onTakeSeat: _takeSeat,
                        onLeaveSeat: _leaveSeat,
                        isHost: isHost,
                      ),
                      Spacer(),
                    ],
                  ),

                  // Stream options overlay (top bar, chat, bottom buttons)
                  // IgnorePointer(
                  //   ignoring: true,
                  //   child: _buildStreamOptions(state),
                  // ),

                  // Individual UI components (not blocking the entire screen)
                  _buildTopBar(state),
                  _buildChatWidget(),
                  _buildBottomButtons(state),

                  // Positioned(
                  //   bottom: 180.h,
                  //   left: 20.w,
                  //   right: 20.w,
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       debugPrint("\n\n\nSelected seat index: \n\n\n");
                  //     },
                  //     child: Text("Take Seat"),
                  //   ),
                  // ),

                  // Animation layer
                  if (_animationPlaying)
                    AnimatedLayer(
                      gifts: [], // sentGifts,
                      customAnimationUrl: _customAnimationUrl,
                      customTitle: _customAnimationTitle,
                      customSubtitle: _customAnimationSubtitle,
                    ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  /// ###################### Build functions to build UI components ######################
  /// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  Widget _buildTopBar(AuthAuthenticated state) {
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
                JoindListenersPage(
                  activeUserList: listeners,
                  hostUserId: isHost ? userId : widget.hostUserId,
                  hostName: isHost ? state.user.name : widget.hostName,
                  hostAvatar: isHost ? state.user.avatar : widget.hostAvatar,
                ),
                // Leave button
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

  Widget _buildChatWidget() {
    return Positioned(
      left: 20.w,
      bottom: 120.h, // Above the bottom buttons
      child: Container(
        color: Colors.transparent,
        child: AudioChatWidget(messages: _chatMessages),
      ),
    );
  }

  Widget _buildBottomButtons(AuthAuthenticated state) {
    return Positioned(
      bottom: 30.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        color: Colors.transparent,
        child: isHost
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
                    iconPath: _muted ? "assets/icons/mute_icon.png" : "assets/icons/unmute_icon.png",
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
                      showGameBottomSheet(context, userId: userId, isHost: isHost, streamDuration: _streamDuration);
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
                      //   activeViewers: listeners,
                      //   roomId: _currentRoomId ?? roomId,
                      //   hostUserId: isHost ? userId : widget.hostUserId,
                      //   hostName: isHost ? state.user.name : widget.hostName,
                      //   hostAvatar: isHost ? state.user.avatar : widget.hostAvatar,
                      // );
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
    // Cancel all stream subscriptions
    _connectionStatusSubscription?.cancel();
    _getAllRoomsSubscription?.cancel(); // 1
    _audioRoomDetailsSubscription?.cancel(); // 2
    _createRoomSubscription?.cancel(); // 3
    _closeRoomSubscription?.cancel(); // 4
    _joinRoomSubscription?.cancel(); // 5
    _leaveRoomSubscription?.cancel(); // 6
    _userLeftSubscription?.cancel(); // 7
    _joinSeatSubscription?.cancel(); // 8
    _leaveSeatSubscription?.cancel(); // 9
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
