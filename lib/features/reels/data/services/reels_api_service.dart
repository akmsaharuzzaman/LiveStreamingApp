import 'dart:convert';
import 'dart:developer';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/api_constants.dart';
import '../models/reel_model.dart';

class ReelsApiService {
  final ApiService _apiService;

  ReelsApiService(this._apiService);

  /// Fetch reels from API
  Future<ReelsApiResponse> getReels({int page = 1, int limit = 10}) async {
    try {
      log('Fetching reels from: ${ApiConstants.getReels(page, limit)}');

      final result = await _apiService.get(ApiConstants.getReels(page, limit));

      log('API Result type: ${result.runtimeType}');
      log('API Result: $result');

      return result.when(
        success: (data) {
          log('Success data type: ${data.runtimeType}');
          log('Success data: $data');

          if (data is Map<String, dynamic>) {
            return ReelsApiResponse.fromJson(data);
          } else if (data is String) {
            final Map<String, dynamic> jsonData = json.decode(data);
            return ReelsApiResponse.fromJson(jsonData);
          } else {
            throw Exception('Unexpected response format: ${data.runtimeType}');
          }
        },
        failure: (error) {
          log('API Failure: $error');
          throw Exception('Failed to load reels: $error');
        },
      );
    } catch (e) {
      log('Exception in getReels: $e');
      throw Exception('Error fetching reels: $e');
    }
  }

  /// React to a reel
  Future<bool> reactToReel({
    required String reelId,
    required String reactionType, // 'like', 'love', 'laugh', etc.
  }) async {
    try {
      log('Reacting to reel: $reelId with reaction: $reactionType');
      
      final result = await _apiService.post(
        ApiConstants.reactToReel,
        data: {
          'reelId': reelId,
          'reaction_type': reactionType,
        },
      );

      return result.when(
        success: (data) {
          log('Successfully reacted to reel: $data');
          return true;
        },
        failure: (error) {
          log('Error reacting to reel: $error');
          return false;
        },
      );
    } catch (e) {
      log('Error reacting to reel: $e');
      return false;
    }
  }

  /// Add comment to a reel
  Future<bool> commentOnReel({
    required String reelId,
    required String comment,
  }) async {
    try {
      log('Adding comment to reel: $reelId');
      
      final result = await _apiService.post(
        ApiConstants.commentOnReel,
        data: {
          'reelId': reelId,
          'comment': comment,
        },
      );

      return result.when(
        success: (data) {
          log('Successfully added comment to reel: $data');
          return true;
        },
        failure: (error) {
          log('Error commenting on reel: $error');
          return false;
        },
      );
    } catch (e) {
      log('Error commenting on reel: $e');
      return false;
    }
  }

  /// Share a reel
  Future<bool> shareReel({required String reelId}) async {
    try {
      final result = await _apiService.post(
        ApiConstants.shareReel(reelId),
        data: {},
      );

      return result.when(
        success: (data) => true,
        failure: (error) {
          log('Error sharing reel: $error');
          return false;
        },
      );
    } catch (e) {
      log('Error sharing reel: $e');
      return false;
    }
  }

  /// Follow a user
  Future<bool> followUser({required String userId}) async {
    try {
      final result = await _apiService.post(
        ApiConstants.followUser,
        data: {'userId': userId},
      );

      return result.when(
        success: (data) => true,
        failure: (error) {
          log('Error following user: $error');
          return false;
        },
      );
    } catch (e) {
      log('Error following user: $e');
      return false;
    }
  }

  /// Get comments for a reel
  Future<Map<String, dynamic>?> getReelComments({
    required String reelId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      log('Getting comments for reel: $reelId');
      
      final result = await _apiService.get(
        ApiConstants.getReelComments(reelId, page, limit),
      );

      return result.when(
        success: (data) {
          log('Successfully got comments for reel: $data');
          return data as Map<String, dynamic>?;
        },
        failure: (error) {
          log('Error getting reel comments: $error');
          return null;
        },
      );
    } catch (e) {
      log('Error getting reel comments: $e');
      return null;
    }
  }

  /// Edit a comment on a reel
  Future<bool> editReelComment({
    required String commentId,
    required String newComment,
  }) async {
    try {
      log('Editing comment: $commentId');
      
      final result = await _apiService.put(
        ApiConstants.editReelComment,
        data: {
          'commentId': commentId,
          'newComment': newComment,
        },
      );

      return result.when(
        success: (data) {
          log('Successfully edited comment: $data');
          return true;
        },
        failure: (error) {
          log('Error editing comment: $error');
          return false;
        },
      );
    } catch (e) {
      log('Error editing comment: $e');
      return false;
    }
  }

  /// Delete a comment on a reel
  Future<bool> deleteReelComment({
    required String reelId,
    required String commentId,
  }) async {
    try {
      log('Deleting comment: $commentId from reel: $reelId');
      
      final result = await _apiService.delete(
        ApiConstants.deleteReelComment(reelId, commentId),
      );

      return result.when(
        success: (data) {
          log('Successfully deleted comment: $data');
          return true;
        },
        failure: (error) {
          log('Error deleting comment: $error');
          return false;
        },
      );
    } catch (e) {
      log('Error deleting comment: $e');
      return false;
    }
  }

  /// React to a comment on a reel
  Future<bool> reactToReelComment({
    required String commentId,
    required String reactionType,
  }) async {
    try {
      log('Reacting to comment: $commentId with reaction: $reactionType');
      
      final result = await _apiService.post(
        ApiConstants.reactToReelComment,
        data: {
          'commentId': commentId,
          'reaction_type': reactionType,
        },
      );

      return result.when(
        success: (data) {
          log('Successfully reacted to comment: $data');
          return true;
        },
        failure: (error) {
          log('Error reacting to comment: $error');
          return false;
        },
      );
    } catch (e) {
      log('Error reacting to comment: $e');
      return false;
    }
  }

  /// Reply to a comment on a reel
  Future<bool> replyToReelComment({
    required String commentId,
    required String reelId,
    required String commentText,
  }) async {
    try {
      log('Replying to comment: $commentId on reel: $reelId');
      
      final result = await _apiService.post(
        ApiConstants.replyToReelComment,
        data: {
          'commentId': commentId,
          'reelId': reelId,
          'commentText': commentText,
        },
      );

      return result.when(
        success: (data) {
          log('Successfully replied to comment: $data');
          return true;
        },
        failure: (error) {
          log('Error replying to comment: $error');
          return false;
        },
      );
    } catch (e) {
      log('Error replying to comment: $e');
      return false;
    }
  }

  /// Test connection to reels API for debugging
  Future<void> testConnection() async {
    try {
      log('Testing connection to reels API...');
      log('Base URL: ${ApiConstants.baseUrl}');
      log('Endpoint: ${ApiConstants.getReels(1, 5)}');

      final result = await _apiService.get(ApiConstants.getReels(1, 5));

      result.when(
        success: (data) {
          log('✅ Connection successful!');
          log('Response type: ${data.runtimeType}');
          log('Response data: $data');
        },
        failure: (error) {
          log('❌ Connection failed: $error');
        },
      );
    } catch (e) {
      log('❌ Exception during connection test: $e');
    }
  }
}
