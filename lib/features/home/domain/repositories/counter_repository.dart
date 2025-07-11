import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/counter.dart';

abstract class CounterRepository {
  Future<Either<Failure, Counter>> getCounter();
  Future<Either<Failure, Counter>> incrementCounter();
  Future<Either<Failure, Counter>> decrementCounter();
  Future<Either<Failure, void>> resetCounter();
}
