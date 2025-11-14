import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/audio_room_details.dart';
import '../../data/models/chat_model.dart';

/// Base state class for AudioRoomBloc
abstract class AudioRoomState extends Equatable {
  const AudioRoomState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AudioRoomInitial extends AudioRoomState {}

/// Loading state
class AudioRoomLoading extends AudioRoomState {}

/// Socket connected state
class AudioRoomConnected extends AudioRoomState {
  final String userId;
  final bool isConnected;

  const AudioRoomConnected({required this.userId, required this.isConnected});

  @override
  List<Object?> get props => [userId, isConnected];
}

/// Room loaded state
class AudioRoomLoaded extends AudioRoomState {
  final AudioRoomDetails? roomData;
  final List<AudioChatModel> chatMessages;
  final List<AudioMember> listeners;
  final List<String> bannedUsers;
  final String? currentRoomId;
  final String? userId;
  final bool isHost;
  final bool isConnected;
  final bool isMuted;
  final bool isAudioCaller;
  final List<int> audioCallerUids;
  final bool isBroadcaster;
  final String? activeSpeakerUserId;
  // Animation
  final bool playAnimation;
  final GiftModel? giftDetails;

  const AudioRoomLoaded({
    this.roomData,
    this.chatMessages = const [],
    this.listeners = const [],
    this.bannedUsers = const [],
    this.currentRoomId,
    this.userId,
    this.isHost = false,
    this.isConnected = false,
    this.isMuted = false,
    this.isAudioCaller = false,
    this.audioCallerUids = const [],
    this.playAnimation = false,
    this.giftDetails,
    this.isBroadcaster = false,
    this.activeSpeakerUserId,
  });

  AudioRoomLoaded copyWith({
    AudioRoomDetails? roomData,
    List<AudioChatModel>? chatMessages,
    List<AudioMember>? listeners,
    List<String>? bannedUsers,
    String? currentRoomId,
    String? userId,
    bool? isHost,
    bool? isConnected,
    bool? isMuted,
    bool? isAudioCaller,
    List<int>? audioCallerUids,
    DateTime? streamStartTime,
    Duration? streamDuration,
    bool? playAnimation,
    GiftModel? giftDetails,
    bool? isBroadcaster,
    String? activeSpeakerUserId,
    bool clearActiveSpeaker = false,
  }) {
    return AudioRoomLoaded(
      roomData: roomData ?? this.roomData,
      chatMessages: chatMessages ?? this.chatMessages,
      listeners: listeners ?? this.listeners,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      userId: userId ?? this.userId,
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
      isMuted: isMuted ?? this.isMuted,
      isAudioCaller: isAudioCaller ?? this.isAudioCaller,
      audioCallerUids: audioCallerUids ?? this.audioCallerUids,
      playAnimation: playAnimation ?? this.playAnimation,
      giftDetails: giftDetails ?? this.giftDetails,
      isBroadcaster: isBroadcaster ?? this.isBroadcaster,
      activeSpeakerUserId: clearActiveSpeaker ? null : (activeSpeakerUserId ?? this.activeSpeakerUserId),
    );
  }

  @override
  List<Object?> get props => [
    roomData,
    chatMessages,
    listeners,
    bannedUsers,
    currentRoomId,
    userId,
    isHost,
    isConnected,
    isMuted,
    isAudioCaller,
    audioCallerUids,
    playAnimation,
    giftDetails,
    isBroadcaster,
    activeSpeakerUserId,
  ];
}

/// Room closed state
class AudioRoomClosed extends AudioRoomState {
  final String? reason;

  const AudioRoomClosed({this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Error state
class AudioRoomError extends AudioRoomState {
  final String message;
  final String? errorCode;

  const AudioRoomError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
