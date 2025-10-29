import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/merged_api_service.dart';
import '../models/chat_models.dart';

@injectable
class ChatApiService {
  final ApiService _apiService;

  ChatApiService(this._apiService);

  static const String _baseUrl = 'http://31.97.222.97:8000/api/chats';

  /// Send a message
  Future<ApiResult<ChatMessage>> sendMessage({
    required String receiverId,
    required String text,
    File? file,
  }) async {
    try {
      // Create FormData for the request (matching your Postman request)
      final formData = FormData.fromMap({
        'reciever': receiverId, // Backend expects 'reciever' (with typo)
        'text': text,
        if (file != null) 'file': await MultipartFile.fromFile(file.path),
      });

      debugPrint('Sending message to $receiverId: $text');

      // Use post with FormData
      final result = await _apiService.post(
        '$_baseUrl/send-message/',
        data: formData,
      );

      return result.fold(
        (data) {
          if (data['success'] == true && data['result'] != null) {
            debugPrint('Send message response: ${data['result']}');
            final message = ChatMessage.fromJson(data['result']);
            debugPrint(
              'Parsed message sender ID: ${message.sender?.id}, sender name: ${message.sender?.name}',
            );
            return ApiResult.success(message);
          } else {
            return ApiResult.failure(
              data['message'] ?? 'Failed to send message',
            );
          }
        },
        (error) {
          debugPrint('Send message error: $error');
          return ApiResult.failure(error);
        },
      );
    } catch (e) {
      debugPrint('Send message exception: $e');
      return ApiResult.failure('Failed to send message: ${e.toString()}');
    }
  }

  /// Mark messages as seen
  Future<ApiResult<Map<String, dynamic>>> markMessagesSeen({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final result = await _apiService.put(
        '$_baseUrl/seen-message/',
        data: {'sender': senderId, 'reciever': receiverId},
      );

      return result.fold((data) {
        if (data['success'] == true) {
          return ApiResult.success(data['result']);
        } else {
          return ApiResult.failure(
            data['message'] ?? 'Failed to mark messages as seen',
          );
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure(
        'Failed to mark messages as seen: ${e.toString()}',
      );
    }
  }

  /// Edit a message
  Future<ApiResult<ChatMessage>> editMessage({
    required String messageId,
    required String newText,
  }) async {
    try {
      final result = await _apiService.put(
        '$_baseUrl/edit-message/$messageId',
        data: {'newText': newText},
      );

      return result.fold((data) {
        if (data['success'] == true && data['result'] != null) {
          final message = ChatMessage.fromJson(data['result']);
          return ApiResult.success(message);
        } else {
          return ApiResult.failure(data['message'] ?? 'Failed to edit message');
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Failed to edit message: ${e.toString()}');
    }
  }

  /// Get all messages in a room with another user
  Future<ApiResult<List<ChatMessage>>> getAllMessages({
    required String otherUserId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final result = await _apiService.get(
        '$_baseUrl/all-message/$otherUserId',
        queryParameters: {'page': page, 'limit': limit},
      );

      return result.fold((data) {
        if (data['success'] == true && data['result'] != null) {
          final List<dynamic> messagesData = data['result']['data'] ?? [];
          final messages = messagesData
              .map((messageJson) => ChatMessage.fromJson(messageJson))
              .toList();
          return ApiResult.success(messages);
        } else {
          return ApiResult.failure(data['message'] ?? 'Failed to get messages');
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Failed to get messages: ${e.toString()}');
    }
  }

  /// Get all conversations
  Future<ApiResult<List<Conversation>>> getAllConversations({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final result = await _apiService.get(
        '$_baseUrl/all-conversation',
        queryParameters: {'page': page, 'limit': limit},
      );

      return result.fold((data) {
        if (data['success'] == true && data['result'] != null) {
          final List<dynamic> conversationsData = data['result']['data'] ?? [];
          final conversations = conversationsData
              .map(
                (conversationJson) => Conversation.fromJson(conversationJson),
              )
              .toList();
          return ApiResult.success(conversations);
        } else {
          return ApiResult.failure(
            data['message'] ?? 'Failed to get conversations',
          );
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Failed to get conversations: ${e.toString()}');
    }
  }

  /// Delete a message
  Future<ApiResult<bool>> deleteMessage({required String messageId}) async {
    try {
      final result = await _apiService.delete(
        '$_baseUrl/delete-message/$messageId',
      );

      return result.fold((data) {
        if (data['success'] == true) {
          return const ApiResult.success(true);
        } else {
          return ApiResult.failure(
            data['message'] ?? 'Failed to delete message',
          );
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Failed to delete message: ${e.toString()}');
    }
  }

  /// Delete a full conversation
  Future<ApiResult<bool>> deleteConversation({
    required String conversationId,
  }) async {
    try {
      final result = await _apiService.delete(
        '$_baseUrl/delete-conversation/$conversationId',
      );

      return result.fold((data) {
        if (data['success'] == true) {
          return const ApiResult.success(true);
        } else {
          return ApiResult.failure(
            data['message'] ?? 'Failed to delete conversation',
          );
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure(
        'Failed to delete conversation: ${e.toString()}',
      );
    }
  }

  /// Block a user
  Future<ApiResult<Map<String, dynamic>>> blockUser({
    required String userId,
  }) async {
    try {
      final result = await _apiService.post('$_baseUrl/block-user/$userId');

      return result.fold((data) {
        if (data['success'] == true) {
          return ApiResult.success(data['result'] ?? {});
        } else {
          return ApiResult.failure(data['message'] ?? 'Failed to block user');
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Failed to block user: ${e.toString()}');
    }
  }

  /// Unblock a user
  Future<ApiResult<Map<String, dynamic>>> unblockUser({
    required String userId,
  }) async {
    try {
      final result = await _apiService.delete('$_baseUrl/block-user/$userId');

      return result.fold((data) {
        if (data['success'] == true) {
          return ApiResult.success(data['result'] ?? {});
        } else {
          return ApiResult.failure(data['message'] ?? 'Failed to unblock user');
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Failed to unblock user: ${e.toString()}');
    }
  }

  /// Get block status for a user
  Future<ApiResult<bool>> getBlockStatus({required String userId}) async {
    try {
      final result = await _apiService.get('$_baseUrl/block-status/$userId');

      return result.fold((data) {
        if (data['success'] == true && data['result'] != null) {
          final isBlocked = data['result']['isBlocked'] ?? false;
          return ApiResult.success(isBlocked);
        } else {
          return ApiResult.failure(
            data['message'] ?? 'Failed to get block status',
          );
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Failed to get block status: ${e.toString()}');
    }
  }
}
