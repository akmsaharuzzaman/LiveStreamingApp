class BanUserModel {
  final String roomId;
  final String targetId;
  final String message;

  BanUserModel({
    required this.roomId,
    required this.targetId,
    required this.message,
  });

  factory BanUserModel.fromJson(Map<String, dynamic> json) {
    return BanUserModel(
      roomId: json['roomId'] as String,
      targetId: json['targetId'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'targetId': targetId,
      'message': message,
    };
  }
}
