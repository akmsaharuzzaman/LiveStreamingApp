import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/counter.dart';
import '../../domain/repositories/counter_repository.dart';
import '../datasources/counter_local_data_source.dart';
import '../models/counter_model.dart';

@Injectable(as: CounterRepository)
class CounterRepositoryImpl implements CounterRepository {
  final CounterLocalDataSource localDataSource;

  CounterRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, Counter>> getCounter() async {
    try {
      final counterModel = await localDataSource.getCounter();
      return Right(counterModel.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Counter>> incrementCounter() async {
    try {
      final currentCounter = await localDataSource.getCounter();
      final newCounter = CounterModel(
        value: currentCounter.value + 1,
        lastUpdated: DateTime.now(),
      );
      await localDataSource.cacheCounter(newCounter);
      return Right(newCounter.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to increment counter'));
    }
  }

  @override
  Future<Either<Failure, Counter>> decrementCounter() async {
    try {
      final currentCounter = await localDataSource.getCounter();
      final newCounter = CounterModel(
        value: currentCounter.value - 1,
        lastUpdated: DateTime.now(),
      );
      await localDataSource.cacheCounter(newCounter);
      return Right(newCounter.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to decrement counter'));
    }
  }

  @override
  Future<Either<Failure, void>> resetCounter() async {
    try {
      await localDataSource.clearCounter();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to reset counter'));
    }
  }
}
