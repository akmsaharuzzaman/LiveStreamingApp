import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/counter.dart';
import '../repositories/counter_repository.dart';

@injectable
class IncrementCounter {
  final CounterRepository repository;

  IncrementCounter(this.repository);

  Future<Either<Failure, Counter>> call() async {
    return await repository.incrementCounter();
  }
}
