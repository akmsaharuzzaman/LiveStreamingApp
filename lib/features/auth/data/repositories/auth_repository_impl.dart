import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;

  AuthRepositoryImpl({required this.apiService});

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString(
        'uid',
      ); // Get user ID from SharedPreferences

      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      if (userId == null || userId.isEmpty) {
        throw Exception('No user ID found');
      }

      final response = await apiService.get<Map<String, dynamic>>(
        '/api/auth/user/$userId', // Correct endpoint format
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.when(
        success: (data) {
          if (data['success'] == true && data['result'] != null) {
            return UserModel.fromJson(data['result']);
          } else {
            throw Exception('Invalid response format');
          }
        },
        failure: (error) => throw Exception('Failed to get user data: $error'),
      );
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('uid'); // Also remove user ID
      await prefs.remove('user_data');
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
}
