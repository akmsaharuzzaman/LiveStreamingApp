import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/counter.dart';
import '../../domain/usecases/get_counter.dart';
import '../../domain/usecases/increment_counter.dart';

part 'counter_event.dart';
part 'counter_state.dart';

@injectable
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  final GetCounter getCounter;
  final IncrementCounter incrementCounter;

  CounterBloc({required this.getCounter, required this.incrementCounter})
    : super(CounterInitial()) {
    on<CounterStarted>(_onCounterStarted);
    on<CounterIncremented>(_onCounterIncremented);
  }

  Future<void> _onCounterStarted(
    CounterStarted event,
    Emitter<CounterState> emit,
  ) async {
    emit(CounterLoading());

    final result = await getCounter();
    result.fold(
      (failure) => emit(CounterError(failure.message)),
      (counter) => emit(CounterLoaded(counter)),
    );
  }

  Future<void> _onCounterIncremented(
    CounterIncremented event,
    Emitter<CounterState> emit,
  ) async {
    if (state is CounterLoaded) {
      emit(CounterLoading());

      final result = await incrementCounter();
      result.fold(
        (failure) => emit(CounterError(failure.message)),
        (counter) => emit(CounterLoaded(counter)),
      );
    }
  }
}
