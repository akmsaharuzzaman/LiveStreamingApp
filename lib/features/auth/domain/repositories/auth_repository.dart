import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> getCurrentUser();
  Future<void> logout();
}
