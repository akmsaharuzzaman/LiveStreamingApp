import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserEvent extends AuthEvent {
  const LoadUserEvent();
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class UpdateUserEvent extends AuthEvent {
  final UserEntity user;

  const UpdateUserEvent(this.user);

  @override
  List<Object?> get props => [user];
}
