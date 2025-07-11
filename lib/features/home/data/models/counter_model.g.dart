// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CounterModel _$CounterModelFromJson(Map<String, dynamic> json) => CounterModel(
  value: (json['value'] as num).toInt(),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$CounterModelToJson(CounterModel instance) =>
    <String, dynamic>{
      'value': instance.value,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
