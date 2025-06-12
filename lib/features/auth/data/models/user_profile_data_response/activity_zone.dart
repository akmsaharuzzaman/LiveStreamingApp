import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_zone.g.dart';

@JsonSerializable()
class ActivityZone extends Equatable {
  final String? zone;

  const ActivityZone({this.zone});

  factory ActivityZone.fromJson(Map<String, dynamic> json) {
    return _$ActivityZoneFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ActivityZoneToJson(this);

  ActivityZone copyWith({
    String? zone,
  }) {
    return ActivityZone(
      zone: zone ?? this.zone,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [zone];
}
