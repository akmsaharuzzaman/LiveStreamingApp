import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'avatar.g.dart';

@JsonSerializable()
class Avatar extends Equatable {
  final String? name;
  final String? url;

  const Avatar({this.name, this.url});

  factory Avatar.fromJson(Map<String, dynamic> json) => _$AvatarFromJson(json);

  Map<String, dynamic> toJson() => _$AvatarToJson(this);

  @override
  List<Object?> get props => [name, url];
}
