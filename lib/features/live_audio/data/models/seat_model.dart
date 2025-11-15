import 'package:dlstarlive/core/utils/app_utils.dart';

class SeatModel {
  final String id;
  final String? name;
  final String? avatar;
  final bool isLocked;
  final bool isMuted;
  //  final double? diamonds;
  final String? userId; // User ID occupying this seat
  final int? userUID; // User UID occupying this seat

  // Generate seat key (seat-1, seat-2, etc.)
  String get seatKey => 'seat-$id';

  SeatModel({
    required this.id,
    this.name,
    this.avatar,
    this.isLocked = false,
    this.isMuted = false,
    // this.diamonds,
    this.userId,
    this.userUID,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      isLocked: json['isLocked'] as bool,
      isMuted: json['isMuted'] as bool,
      // diamonds: json['diamonds'] as double?,
      userId: json['userId'] as String?,
      // userUID: int.tryParse(json['uid'].hashCode.toString()),
      userUID: AppUtils.getIntFromUid(json['uid']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isLocked': isLocked,
      'isMuted': isMuted,
      // 'diamonds': diamonds,
      'userId': userId,
      'userUID': userUID,
    };
  }
}
