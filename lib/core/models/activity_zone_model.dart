import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_zone_model.g.dart';

/// Activity zone model for the backend response
@JsonSerializable()
class ActivityZoneModel extends Equatable {
  final String zone;

  const ActivityZoneModel({
    required this.zone,
  });

  factory ActivityZoneModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityZoneModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityZoneModelToJson(this);

  @override
  List<Object?> get props => [zone];
}
