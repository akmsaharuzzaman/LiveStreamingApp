import 'package:dlstarlive/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../network/api_clients.dart';
import 'google_auth_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthInitializeEvent extends AuthEvent {
  const AuthInitializeEvent();
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;

  const AuthRegisterEvent({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  @override
  List<Object?> get props => [email, password, firstName, lastName, phone];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthRefreshTokenEvent extends AuthEvent {
  const AuthRefreshTokenEvent();
}

class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}

class AuthGoogleSignInEvent extends AuthEvent {
  const AuthGoogleSignInEvent();
}

class AuthUpdateProfileEvent extends AuthEvent {
  final String country;
  final String gender;
  final DateTime birthday;

  const AuthUpdateProfileEvent({
    required this.country,
    required this.gender,
    required this.birthday,
  });

  @override
  List<Object?> get props => [country, gender, birthday];
}

class AuthUpdateUserProfileEvent extends AuthEvent {
  final String? name;
  final String? firstName;
  final File? avatarFile;
  final String? gender;

  const AuthUpdateUserProfileEvent({
    this.name,
    this.firstName,
    this.avatarFile,
    this.gender,
  });

  @override
  List<Object?> get props => [name, firstName, avatarFile];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthSplashLoading extends AuthState {
  const AuthSplashLoading();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthTokenExpired extends AuthState {
  const AuthTokenExpired();
}

class AuthProfileIncomplete extends AuthState {
  final UserModel user;
  final String token;

  const AuthProfileIncomplete({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

// BLoC
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthApiClient _authApiClient;
  final UserApiClient _userApiClient;
  final GoogleAuthService _googleAuthService;

  String? _currentToken;
  UserModel? _currentUser;

  AuthBloc(this._authApiClient, this._userApiClient, this._googleAuthService)
    : super(const AuthInitial()) {
    on<AuthInitializeEvent>(_onInitialize);
    on<AuthLoginEvent>(_onLogin);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthRefreshTokenEvent>(_onRefreshToken);
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthGoogleSignInEvent>(_onGoogleSignIn);
    on<AuthUpdateProfileEvent>(_onUpdateProfile);
    on<AuthUpdateUserProfileEvent>(_onUpdateUserProfile);
  }

  // Getters for easy access to current auth state
  bool get isAuthenticated => state is AuthAuthenticated;
  String? get currentToken => _currentToken;
  UserModel? get currentUser => _currentUser;

  Future<void> _onInitialize(
    AuthInitializeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSplashLoading());

    try {
      // Initialize Google Sign-In service (required for v7)
      // await _googleAuthService.initialize();

      // Initialize auth from stored token
      await _authApiClient.initializeAuth();

      // Check if user is logged in
      final isLoggedIn = await _authApiClient.isLoggedIn();

      if (isLoggedIn) {
        // Try to fetch user profile to validate token
        final profileResponse = await _userApiClient.getUserProfile();

        if (profileResponse.isSuccess && profileResponse.data != null) {
          // For getUserProfile, the user data is directly in 'result' (object)
          final userData =
              profileResponse.data!['result'] as Map<String, dynamic>?;
          if (userData != null) {
            final userEntity = UserModel.fromJson(userData);

            _currentUser = userEntity;
            _currentToken = await _authApiClient.getStoredToken();

            // Debug profile completion fields
            debugPrint('User profile completion check:');
            debugPrint('Country: ${_currentUser!.countryLanguages.toList()}');
            debugPrint('Gender: ${_currentUser!.gender}');
            debugPrint('Birthday: ${_currentUser!.birthday}');
            debugPrint(
              'Is profile complete: ${_currentUser!.isProfileComplete}',
            );

            if (!_currentUser!.isProfileComplete) {
              debugPrint(
                'Profile is incomplete, emitting AuthProfileIncomplete state',
              );
              emit(
                AuthProfileIncomplete(
                  user: _currentUser!,
                  token: _currentToken!,
                ),
              );
              return;
            }

            debugPrint('Profile is complete, emitting AuthAuthenticated state');
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          } else {
            // Invalid response structure
            await _authApiClient.logout();
            emit(const AuthUnauthenticated());
          }
        } else {
          // Token is invalid, clear it
          await _authApiClient.logout();
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('Auth initialization error: ${e.toString()}');
      emit(AuthError('Failed to initialize authentication: ${e.toString()}'));
    }
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final response = await _authApiClient.login(event.email, event.password);

      if (response.isSuccess && response.data != null) {
        _currentToken = response.data!['token'] as String?;

        // Fetch user profile after successful login
        final profileResponse = await _userApiClient.getUserProfile();

        if (profileResponse.isSuccess && profileResponse.data != null) {
          // For getUserProfile, the user data is directly in 'result' (object)
          final userData =
              profileResponse.data!['result'] as Map<String, dynamic>?;
          if (userData != null) {
            _currentUser = UserModel.fromJson(userData);
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          } else {
            // Login successful but couldn't fetch profile
            _currentUser = UserModel.fromJson(
              response.data!['user'] as Map<String, dynamic>,
            );
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          }
        } else {
          // Login successful but couldn't fetch profile
          _currentUser = UserModel.fromJson(
            response.data!['user'] as Map<String, dynamic>,
          );

          emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
        }
      } else {
        emit(AuthError(response.message ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError('Login error: ${e.toString()}'));
    }
  }

  Future<void> _onRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _authApiClient.register(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      );

      if (response.isSuccess && response.data != null) {
        _currentToken = response.data!['token'] as String?;

        // Fetch user profile after successful registration
        final profileResponse = await _userApiClient.getUserProfile();

        if (profileResponse.isSuccess && profileResponse.data != null) {
          // For getUserProfile, the user data is directly in 'result' (object)
          final userData =
              profileResponse.data!['result'] as Map<String, dynamic>?;
          if (userData != null) {
            _currentUser = UserModel.fromJson(userData);
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          } else {
            // Registration successful but couldn't fetch profile
            _currentUser = UserModel.fromJson(
              response.data!['user'] as Map<String, dynamic>,
            );
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          }
        } else {
          // Registration successful but couldn't fetch profile
          _currentUser = UserModel.fromJson(
            response.data!['user'] as Map<String, dynamic>,
          );

          emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
        }
      } else {
        emit(AuthError(response.message ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError('Registration error: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      // Logout from API
      await _authApiClient.logout();

      // Sign out from Google if user is signed in
      if (_googleAuthService.isSignedIn) {
        await _googleAuthService.signOut();
      }

      _currentToken = null;
      _currentUser = null;

      emit(const AuthUnauthenticated());
    } catch (e) {
      // Even if logout API fails, clear local state
      try {
        await _googleAuthService.signOut();
      } catch (_) {
        // Ignore Google sign out errors
      }

      _currentToken = null;
      _currentUser = null;
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onRefreshToken(
    AuthRefreshTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await _authApiClient.refreshToken();

      if (response.isSuccess && response.data != null) {
        _currentToken = response.data!['token'] as String?;

        // Fetch updated user profile
        final profileResponse = await _userApiClient.getUserProfile();

        if (profileResponse.isSuccess && profileResponse.data != null) {
          // For getUserProfile, the user data is directly in 'result' (object)
          final userData =
              profileResponse.data!['result'] as Map<String, dynamic>?;
          if (userData != null) {
            _currentUser = UserModel.fromJson(userData);
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          }
        }
      } else {
        // Token refresh failed, logout user
        await _authApiClient.logout();
        _currentToken = null;
        _currentUser = null;
        emit(const AuthTokenExpired());
      }
    } catch (e) {
      // Token refresh failed, logout user
      await _authApiClient.logout();
      _currentToken = null;
      _currentUser = null;
      emit(const AuthTokenExpired());
    }
  }

  Future<void> _onCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isLoggedIn = await _authApiClient.isLoggedIn();

      if (isLoggedIn && _currentUser != null && _currentToken != null) {
        // Try to fetch fresh user data
        final profileResponse = await _userApiClient.getUserProfile();

        if (profileResponse.isSuccess && profileResponse.data != null) {
          // For getUserProfile, the user data is directly in 'result' (object)
          final userData =
              profileResponse.data!['result'] as Map<String, dynamic>?;
          if (userData != null) {
            _currentUser = UserModel.fromJson(userData);
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          } else {
            // Profile fetch failed, but we still have a token
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          }
        } else {
          // Profile fetch failed, but we still have a token
          emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Status check failed: ${e.toString()}'));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Sign in with Google
      final userModel = await _googleAuthService.signInWithGoogle();

      if (userModel == null) {
        // User canceled the sign-in
        emit(const AuthUnauthenticated());
        return;
      }

      // Send user data to your backend API for registration/login
      final response = await _authApiClient.registerWithGoogle(
        email: userModel.email,
        firstName: userModel.firstName,
        lastName: userModel.lastName,
        googleId: userModel.googleId!,
        profilePictureUrl: userModel.profilePictureUrl,
      );

      if (response.isSuccess && response.data != null) {
        // Handle both token formats for compatibility
        _currentToken =
            response.data!['access_token'] as String? ??
            response.data!['token'] as String?;

        // Extract user data from the 'result' array
        final resultList = response.data!['result'] as List<dynamic>?;
        if (resultList != null && resultList.isNotEmpty) {
          final userData = resultList.first as Map<String, dynamic>;
          _currentUser = UserModel.fromJson(userData);
        } else {
          // Fallback: try to parse directly from response.data
          _currentUser = UserModel.fromJson(
            response.data as Map<String, dynamic>,
          );
        }

        // After successful registration, fetch user profile to get complete data
        final profileResponse = await _userApiClient.getUserProfile();
        if (profileResponse.isSuccess && profileResponse.data != null) {
          final userData =
              profileResponse.data!['result'] as Map<String, dynamic>?;
          if (userData != null) {
            _currentUser = UserModel.fromJson(userData);

            // Check if profile is complete (has country, gender, birthday)
            if (!_currentUser!.isProfileComplete) {
              emit(
                AuthProfileIncomplete(
                  user: _currentUser!,
                  token: _currentToken!,
                ),
              );
              return;
            }
          }
        }

        emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
      } else {
        // If API registration fails, still proceed with local Google auth
        // Create a basic UserModel from Google data
        _currentUser = UserModel.fromGoogle(
          email: userModel.email,
          name: userModel.displayName,
          firstName: userModel.firstName,
          lastName: userModel.lastName,
          googleId: userModel.googleId,
          profilePictureUrl: userModel.profilePictureUrl,
        );
        _currentToken =
            'google_token_placeholder'; // You might get this from Firebase

        emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
      }
    } catch (e) {
      // Sign out from Google if authentication fails
      try {
        await _googleAuthService.signOut();
      } catch (_) {
        // Ignore sign out errors
      }

      emit(AuthError('Google sign-in failed: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(
    AuthUpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Update profile using form data
      final response = await _authApiClient.updateProfile(
        country: event.country,
        gender: event.gender,
        birthday: event.birthday,
      );

      if (response.isSuccess && response.data != null) {
        // Fetch updated user profile after successful update
        final profileResponse = await _userApiClient.getUserProfile();

        if (profileResponse.isSuccess && profileResponse.data != null) {
          final userData =
              profileResponse.data!['result'] as Map<String, dynamic>?;
          if (userData != null) {
            _currentUser = UserModel.fromJson(userData);
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          } else {
            emit(const AuthError('Failed to fetch updated profile'));
          }
        } else {
          emit(const AuthError('Failed to fetch updated profile'));
        }
      } else {
        emit(AuthError(response.message ?? 'Profile update failed'));
      }
    } catch (e) {
      emit(AuthError('Profile update error: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateUserProfile(
    AuthUpdateUserProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Update user profile using form data
      final response = await _authApiClient.updateUserProfile(
        name: event.name,
        firstName: event.firstName,
        avatarFile: event.avatarFile,
        gender: event.gender,
      );

      if (response.isSuccess && response.data != null) {
        // Fetch updated user profile after successful update
        final profileResponse = await _userApiClient.getUserProfile();

        if (profileResponse.isSuccess && profileResponse.data != null) {
          final userData =
              profileResponse.data!['result'] as Map<String, dynamic>?;
          if (userData != null) {
            _currentUser = UserModel.fromJson(userData);
            emit(AuthAuthenticated(user: _currentUser!, token: _currentToken!));
          } else {
            emit(const AuthError('Failed to fetch updated profile'));
          }
        } else {
          emit(const AuthError('Failed to fetch updated profile'));
        }
      } else {
        emit(AuthError(response.message ?? 'Profile update failed'));
      }
    } catch (e) {
      emit(AuthError('Profile update error: ${e.toString()}'));
    }
  }
}
