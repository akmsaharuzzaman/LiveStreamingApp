import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class AuthProvider extends StatelessWidget {
  final Widget child;

  const AuthProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthDependencyContainer.createAuthBloc()
            ..add(const LoadUserEvent()), // Load user on app start
      child: child,
    );
  }
}

// Extension to easily access AuthBloc from anywhere
extension AuthBlocExtension on BuildContext {
  AuthBloc get authBloc => read<AuthBloc>();

  // Helper methods
  bool get isAuthenticated {
    final state = read<AuthBloc>().state;
    return state is AuthAuthenticated;
  }

  String? get currentUserId {
    final state = read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return state.user.id;
    }
    return null;
  }

  String? get currentUserName {
    final state = read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return state.user.name;
    }
    return null;
  }

  String? get currentUserAvatar {
    final state = read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return state.user.avatar?.url;
    }
    return null;
  }
}
