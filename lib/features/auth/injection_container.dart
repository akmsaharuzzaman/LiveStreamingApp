import '../../../core/network/api_service.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/auth_usecases.dart';
import 'presentation/bloc/auth_bloc.dart';

class AuthDependencyContainer {
  static AuthRepository _createAuthRepository() {
    return AuthRepositoryImpl(apiService: ApiService.instance);
  }

  static GetCurrentUserUseCase _createGetCurrentUserUseCase() {
    return GetCurrentUserUseCase(_createAuthRepository());
  }

  static LogoutUseCase _createLogoutUseCase() {
    return LogoutUseCase(_createAuthRepository());
  }

  static AuthBloc createAuthBloc() {
    return AuthBloc(
      getCurrentUserUseCase: _createGetCurrentUserUseCase(),
      logoutUseCase: _createLogoutUseCase(),
    );
  }
}
