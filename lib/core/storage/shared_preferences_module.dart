import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Module for providing SharedPreferences instance
/// This ensures a single instance is used throughout the app
@module
abstract class SharedPreferencesModule {
  /// Provides a lazily-initialized singleton instance of SharedPreferences
  /// This is more efficient than calling SharedPreferences.getInstance()
  /// multiple times across different data sources
  @preResolve
  @lazySingleton
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
