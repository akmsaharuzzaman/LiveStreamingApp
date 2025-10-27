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

  const AudioRoomConnected({
    required this.userId,
    required this.isConnected,
  });

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
  final DateTime? streamStartTime;
  final Duration streamDuration;
  final bool animationPlaying;
  final String? animationUrl;
  final String? animationTitle;
  final String? animationSubtitle;

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
    this.streamStartTime,
    this.streamDuration = Duration.zero,
    this.animationPlaying = false,
    this.animationUrl,
    this.animationTitle,
    this.animationSubtitle,
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
    bool? animationPlaying,
    String? animationUrl,
    String? animationTitle,
    String? animationSubtitle,
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
      streamStartTime: streamStartTime ?? this.streamStartTime,
      streamDuration: streamDuration ?? this.streamDuration,
      animationPlaying: animationPlaying ?? this.animationPlaying,
      animationUrl: animationUrl ?? this.animationUrl,
      animationTitle: animationTitle ?? this.animationTitle,
      animationSubtitle: animationSubtitle ?? this.animationSubtitle,
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
        streamStartTime,
        streamDuration,
        animationPlaying,
        animationUrl,
        animationTitle,
        animationSubtitle,
      ];
}


/// Room closed state
class AudioRoomClosed extends AudioRoomState {
  final String? reason;

  const AudioRoomClosed({this.reason});

  @override
  List<Object?> get props => [reason];
}


/// Animation state
class AnimationPlaying extends AudioRoomState {
  final String? animationUrl;
  final String? title;
  final String? subtitle;

  const AnimationPlaying({
    this.animationUrl,
    this.title,
    this.subtitle,
  });

  @override
  List<Object?> get props => [animationUrl, title, subtitle];
}

/// Error state
class AudioRoomError extends AudioRoomState {
  final String message;
  final String? errorCode;

  const AudioRoomError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// All rooms loaded state (for room list)
class AudioRoomsLoaded extends AudioRoomState {
  final List<AudioRoomDetails> rooms;

  const AudioRoomsLoaded({required this.rooms});

  @override
  List<Object?> get props => [rooms];
}
