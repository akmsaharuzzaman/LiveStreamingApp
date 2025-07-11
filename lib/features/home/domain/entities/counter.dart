import 'package:equatable/equatable.dart';

class Counter extends Equatable {
  final int value;
  final DateTime lastUpdated;

  const Counter({required this.value, required this.lastUpdated});

  Counter copyWith({int? value, DateTime? lastUpdated}) {
    return Counter(
      value: value ?? this.value,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [value, lastUpdated];
}
