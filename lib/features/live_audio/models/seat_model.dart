class SeatModel {
  final String id;
  final String? name;
  final String? avatar;
  final bool isHost;
  final bool isSpecial;
  final bool isLocked;
  final double? diamonds;
  final String? userId; // User ID occupying this seat

  // Generate seat key (seat-1, seat-2, etc.)
  String get seatKey => 'seat-$id';

  SeatModel({
    required this.id,
    this.name,
    this.avatar,
    this.isHost = false,
    this.isSpecial = false,
    this.isLocked = false,
    this.diamonds,
    this.userId,
  });
}