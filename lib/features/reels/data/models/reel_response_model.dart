import '../models/reel_api_response_model.dart';

/// Response model for reels API calls
class ReelsResponse {
  final bool success;
  final ReelsResult result;

  ReelsResponse({required this.success, required this.result});

  factory ReelsResponse.fromJson(Map<String, dynamic> json) {
    return ReelsResponse(
      success: json['success'] ?? false,
      result: ReelsResult.fromJson(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'result': result.toJson()};
  }
}

/// Data model for individual reel
class ReelModel {
  final String id;
  final String status;
  final int videoLength;
  final int videoMaximumLength;
  final String reelUrl;
  final int reactions;
  final int comments;
  final String createdAt;
  final ReelUserInfo userInfo;
  final List<ReelReaction> latestReactions;
  final ReelReaction? myReaction;

  ReelModel({
    required this.id,
    required this.status,
    required this.videoLength,
    required this.videoMaximumLength,
    required this.reelUrl,
    required this.reactions,
    required this.comments,
    required this.createdAt,
    required this.userInfo,
    required this.latestReactions,
    this.myReaction,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      videoLength: json['video_length'] ?? 0,
      videoMaximumLength: json['video_maximum_length'] ?? 0,
      reelUrl: json['reelUrl'] ?? '',
      reactions: json['reactions'] ?? 0,
      comments: json['comments'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      userInfo: ReelUserInfo.fromJson(json['userInfo'] ?? {}),
      latestReactions:
          (json['latestReactions'] as List<dynamic>?)
              ?.map((item) => ReelReaction.fromJson(item))
              .toList() ??
          [],
      myReaction: json['myReaction'] != null
          ? ReelReaction.fromJson(json['myReaction'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
      'video_length': videoLength,
      'video_maximum_length': videoMaximumLength,
      'reelUrl': reelUrl,
      'reactions': reactions,
      'comments': comments,
      'createdAt': createdAt,
      'userInfo': userInfo.toJson(),
      'latestReactions': latestReactions.map((item) => item.toJson()).toList(),
      'myReaction': myReaction?.toJson(),
    };
  }

  // Helper methods for UI
  bool get hasUserReacted => myReaction != null;
  String? get userReactionType => myReaction?.reactionType;
  String get thumbnailUrl => reelUrl; // For now, use video URL as thumbnail
  String get title => ''; // Add title if needed
  String get description => ''; // Add description if needed
}
