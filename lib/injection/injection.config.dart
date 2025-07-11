// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dlstarlive/core/auth/auth_bloc.dart' as _i832;
import 'package:dlstarlive/core/auth/google_auth_module.dart' as _i43;
import 'package:dlstarlive/core/auth/google_auth_service.dart' as _i831;
import 'package:dlstarlive/core/network/api_clients.dart' as _i755;
import 'package:dlstarlive/core/network/api_example_bloc.dart' as _i324;
import 'package:dlstarlive/core/network/api_service.dart' as _i469;
import 'package:dlstarlive/core/network/network_info.dart' as _i203;
import 'package:dlstarlive/core/network/network_module.dart' as _i473;
import 'package:dlstarlive/core/storage/shared_preferences_module.dart'
    as _i828;
import 'package:dlstarlive/features/home/data/datasources/counter_local_data_source.dart'
    as _i371;
import 'package:dlstarlive/features/home/data/repositories/counter_repository_impl.dart'
    as _i44;
import 'package:dlstarlive/features/home/domain/repositories/counter_repository.dart'
    as _i500;
import 'package:dlstarlive/features/home/domain/usecases/get_counter.dart'
    as _i617;
import 'package:dlstarlive/features/home/domain/usecases/increment_counter.dart'
    as _i31;
import 'package:dlstarlive/features/home/presentation/bloc/counter_bloc.dart'
    as _i617;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final googleAuthModule = _$GoogleAuthModule();
    final networkModule = _$NetworkModule();
    final sharedPreferencesModule = _$SharedPreferencesModule();
    gh.lazySingleton<_i116.GoogleSignIn>(() => googleAuthModule.googleSignIn);
    gh.lazySingleton<_i59.FirebaseAuth>(() => googleAuthModule.firebaseAuth);
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio);
    gh.lazySingleton<_i203.NetworkInfo>(() => networkModule.networkInfo);
    await gh.lazySingletonAsync<_i460.SharedPreferences>(
      () => sharedPreferencesModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i831.GoogleAuthService>(
      () => _i831.GoogleAuthServiceImpl(
        gh<_i116.GoogleSignIn>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i469.ApiService>(() => _i469.ApiService(gh<_i361.Dio>()));
    gh.lazySingleton<_i755.UserApiClient>(
      () => _i755.UserApiClient(gh<_i469.ApiService>()),
    );
    gh.lazySingleton<_i755.FileUploadApiClient>(
      () => _i755.FileUploadApiClient(gh<_i469.ApiService>()),
    );
    gh.lazySingleton<_i755.GenericApiClient>(
      () => _i755.GenericApiClient(gh<_i469.ApiService>()),
    );
    gh.factory<_i371.CounterLocalDataSource>(
      () => _i371.CounterLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i755.AuthApiClient>(
      () => _i755.AuthApiClient(
        gh<_i469.ApiService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i500.CounterRepository>(
      () => _i44.CounterRepositoryImpl(gh<_i371.CounterLocalDataSource>()),
    );
    gh.factory<_i617.GetCounter>(
      () => _i617.GetCounter(gh<_i500.CounterRepository>()),
    );
    gh.factory<_i31.IncrementCounter>(
      () => _i31.IncrementCounter(gh<_i500.CounterRepository>()),
    );
    gh.factory<_i324.ApiExampleBloc>(
      () => _i324.ApiExampleBloc(
        gh<_i755.AuthApiClient>(),
        gh<_i755.UserApiClient>(),
        gh<_i755.FileUploadApiClient>(),
        gh<_i755.GenericApiClient>(),
      ),
    );
    gh.factory<_i832.AuthBloc>(
      () => _i832.AuthBloc(
        gh<_i755.AuthApiClient>(),
        gh<_i755.UserApiClient>(),
        gh<_i831.GoogleAuthService>(),
      ),
    );
    gh.factory<_i617.CounterBloc>(
      () => _i617.CounterBloc(
        getCounter: gh<_i617.GetCounter>(),
        incrementCounter: gh<_i31.IncrementCounter>(),
      ),
    );
    return this;
  }
}

class _$GoogleAuthModule extends _i43.GoogleAuthModule {}

class _$NetworkModule extends _i473.NetworkModule {}

class _$SharedPreferencesModule extends _i828.SharedPreferencesModule {}
