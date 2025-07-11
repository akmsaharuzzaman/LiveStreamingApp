import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_bloc.dart';
import '../models/user_model.dart';
import 'i_auth_service.dart';

/// Adapter class that provides AuthBloc functionality in a simple interface
/// This replaces the simple_auth_service.dart usage
class AuthBlocAdapter implements IAuthService {
  final BuildContext context;

  AuthBlocAdapter(this.context);

  /// Get the current authentication token from AuthBloc
  @override
  Future<String?> getToken() async {
    final authBloc = context.read<AuthBloc>();
    return authBloc.currentToken;
  }

  /// Check if user is authenticated
  @override
  Future<bool> isAuthenticated() async {
    final authBloc = context.read<AuthBloc>();
    return authBloc.isAuthenticated;
  }

  /// Get the current user ID
  String? getCurrentUserId() {
    final authBloc = context.read<AuthBloc>();
    return authBloc.currentUser?.id;
  }

  /// Get the current user
  UserModel? getCurrentUser() {
    final authBloc = context.read<AuthBloc>();
    return authBloc.currentUser;
  }

  /// Store token (not needed since AuthBloc handles this)
  @override
  Future<void> setToken(String token) async {
    // This is handled by AuthBloc, so we don't need to implement
    // Just kept for interface compatibility
  }

  /// Remove token (not needed since AuthBloc handles this)
  @override
  Future<void> removeToken() async {
    // This is handled by AuthBloc logout
    // Just kept for interface compatibility
  }
}
