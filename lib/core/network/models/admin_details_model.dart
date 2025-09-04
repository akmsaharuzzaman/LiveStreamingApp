class AdminDetailsModel {
  final String name;
  final String avatar;
  final String uid;
  final String id;
  final String message;

  AdminDetailsModel({
    required this.name,
    required this.avatar,
    required this.uid,
    required this.id,
    required this.message,
  });

  factory AdminDetailsModel.fromJson(Map<String, dynamic> json) {
    return AdminDetailsModel(
      name: json['adminDetails']['name'],
      avatar: json['adminDetails']['avatar'],
      uid: json['adminDetails']['uid'],
      id: json['adminDetails']['_id'], // <-- updated here
      message: json['message'],
    );
  }
}
