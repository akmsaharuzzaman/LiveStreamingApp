class SeatModel {
  final String id;
  final String? name;
  final String? avatar;
  final bool isLocked;
  //  final double? diamonds;
  final String? userId; // User ID occupying this seat

  // Generate seat key (seat-1, seat-2, etc.)
  String get seatKey => 'seat-$id';

  SeatModel({
    required this.id,
    this.name,
    this.avatar,
    this.isLocked = false,
    // this.diamonds,
    this.userId,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      isLocked: json['isLocked'] as bool,
      // diamonds: json['diamonds'] as double?,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isLocked': isLocked,
      // 'diamonds': diamonds,
      'userId': userId,
    };
  }
}