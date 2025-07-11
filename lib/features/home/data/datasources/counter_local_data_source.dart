import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/counter_model.dart';

abstract class CounterLocalDataSource {
  Future<CounterModel> getCounter();
  Future<void> cacheCounter(CounterModel counter);
  Future<void> clearCounter();
}

@Injectable(as: CounterLocalDataSource)
class CounterLocalDataSourceImpl implements CounterLocalDataSource {
  static const String counterKey = 'CACHED_COUNTER';

  final SharedPreferences _sharedPreferences;

  CounterLocalDataSourceImpl(this._sharedPreferences);
  @override
  Future<CounterModel> getCounter() async {
    final jsonString = _sharedPreferences.getString(counterKey);
    if (jsonString != null) {
      try {
        final json = <String, dynamic>{
          'value': _sharedPreferences.getInt('counter_value') ?? 0,
          'lastUpdated':
              _sharedPreferences.getString('counter_last_updated') ??
              DateTime.now().toIso8601String(),
        };
        return CounterModel.fromJson(json);
      } catch (e) {
        throw const CacheException('Failed to load counter from cache');
      }
    } else {
      return CounterModel(value: 0, lastUpdated: DateTime.now());
    }
  }

  @override
  Future<void> cacheCounter(CounterModel counter) async {
    try {
      await _sharedPreferences.setInt('counter_value', counter.value);
      await _sharedPreferences.setString(
        'counter_last_updated',
        counter.lastUpdated.toIso8601String(),
      );
    } catch (e) {
      throw const CacheException('Failed to cache counter');
    }
  }

  @override
  Future<void> clearCounter() async {
    try {
      await _sharedPreferences.remove('counter_value');
      await _sharedPreferences.remove('counter_last_updated');
    } catch (e) {
      throw const CacheException('Failed to clear counter cache');
    }
  }
}
