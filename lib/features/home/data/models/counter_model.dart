import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/counter.dart';

part 'counter_model.g.dart';

@JsonSerializable()
class CounterModel extends Counter {
  const CounterModel({required super.value, required super.lastUpdated});

  factory CounterModel.fromJson(Map<String, dynamic> json) =>
      _$CounterModelFromJson(json);

  Map<String, dynamic> toJson() => _$CounterModelToJson(this);

  factory CounterModel.fromEntity(Counter counter) {
    return CounterModel(value: counter.value, lastUpdated: counter.lastUpdated);
  }

  Counter toEntity() {
    return Counter(value: value, lastUpdated: lastUpdated);
  }
}
