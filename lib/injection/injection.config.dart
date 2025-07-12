// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:dlstarlive/core/auth/auth_bloc.dart' as _i477;
import 'package:dlstarlive/core/auth/google_auth_module.dart' as _i837;
import 'package:dlstarlive/core/auth/google_auth_service.dart' as _i475;
import 'package:dlstarlive/core/network/api_clients.dart' as _i622;
import 'package:dlstarlive/core/network/api_service.dart' as _i10;
import 'package:dlstarlive/core/network/api_service_backup.dart' as _i207;
import 'package:dlstarlive/core/network/merged_api_service.dart' as _i93;
import 'package:dlstarlive/core/network/network_info.dart' as _i1041;
import 'package:dlstarlive/core/network/network_module.dart' as _i809;
import 'package:dlstarlive/core/storage/shared_preferences_module.dart'
    as _i469;
import 'package:dlstarlive/features/chat/data/services/chat_api_service.dart'
    as _i605;
import 'package:dlstarlive/features/chat/presentation/bloc/chat_bloc.dart'
    as _i551;
import 'package:dlstarlive/features/chat/presentation/bloc/chat_detail_bloc.dart'
    as _i684;
import 'package:dlstarlive/features/home/data/datasources/counter_local_data_source.dart'
    as _i618;
import 'package:dlstarlive/features/home/data/repositories/counter_repository_impl.dart'
    as _i756;
import 'package:dlstarlive/features/home/domain/repositories/counter_repository.dart'
    as _i89;
import 'package:dlstarlive/features/home/domain/usecases/get_counter.dart'
    as _i298;
import 'package:dlstarlive/features/home/domain/usecases/increment_counter.dart'
    as _i15;
import 'package:dlstarlive/features/home/presentation/bloc/counter_bloc.dart'
    as _i208;
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
    gh.lazySingleton<_i10.ApiService>(() => _i10.ApiService());
    gh.lazySingleton<_i93.ApiService>(() => _i93.ApiService());
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio);
    gh.lazySingleton<_i1041.NetworkInfo>(() => networkModule.networkInfo);
    await gh.lazySingletonAsync<_i460.SharedPreferences>(
      () => sharedPreferencesModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i475.GoogleAuthService>(
      () => _i475.GoogleAuthServiceImpl(
        gh<_i116.GoogleSignIn>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i622.UserApiClient>(
      () => _i622.UserApiClient(gh<_i10.ApiService>()),
    );
    gh.lazySingleton<_i622.FileUploadApiClient>(
      () => _i622.FileUploadApiClient(gh<_i10.ApiService>()),
    );
    gh.lazySingleton<_i622.GenericApiClient>(
      () => _i622.GenericApiClient(gh<_i10.ApiService>()),
    );
    gh.lazySingleton<_i207.ApiService>(() => _i207.ApiService(gh<_i361.Dio>()));
    gh.factory<_i618.CounterLocalDataSource>(
      () => _i618.CounterLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i622.AuthApiClient>(
      () => _i622.AuthApiClient(
        gh<_i10.ApiService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i605.ChatApiService>(
      () => _i605.ChatApiService(gh<_i93.ApiService>()),
    );
    gh.factory<_i89.CounterRepository>(
      () => _i756.CounterRepositoryImpl(gh<_i618.CounterLocalDataSource>()),
    );
    gh.factory<_i477.AuthBloc>(
      () => _i477.AuthBloc(
        gh<_i622.AuthApiClient>(),
        gh<_i622.UserApiClient>(),
        gh<_i475.GoogleAuthService>(),
      ),
    );
    gh.factory<_i551.ChatBloc>(
      () => _i551.ChatBloc(gh<_i605.ChatApiService>()),
    );
    gh.factory<_i684.ChatDetailBloc>(
      () => _i684.ChatDetailBloc(gh<_i605.ChatApiService>()),
    );
    gh.factory<_i298.GetCounter>(
      () => _i298.GetCounter(gh<_i89.CounterRepository>()),
    );
    gh.factory<_i15.IncrementCounter>(
      () => _i15.IncrementCounter(gh<_i89.CounterRepository>()),
    );
    gh.factory<_i208.CounterBloc>(
      () => _i208.CounterBloc(
        getCounter: gh<_i298.GetCounter>(),
        incrementCounter: gh<_i15.IncrementCounter>(),
      ),
    );
    return this;
  }
}

class _$GoogleAuthModule extends _i837.GoogleAuthModule {}

class _$NetworkModule extends _i809.NetworkModule {}

class _$SharedPreferencesModule extends _i469.SharedPreferencesModule {}
