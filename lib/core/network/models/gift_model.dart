class GiftModel {
  final String? avatar;
  final String name;
  final List<String> recieverIds;
  final int diamonds;
  final int qty;
  final Gift gift;

  GiftModel({
    this.avatar,
    required this.name,
    required this.recieverIds,
    required this.diamonds,
    required this.qty,
    required this.gift,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      avatar: json['avatar'] as String?,
      name: json['name'] as String,
      recieverIds: List<String>.from(json['recieverIds'] as List),
      diamonds: json['diamonds'] as int,
      qty: json['qty'] as int,
      gift: Gift.fromJson(json['gift'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar': avatar,
      'name': name,
      'recieverIds': recieverIds,
      'diamonds': diamonds,
      'qty': qty,
      'gift': gift.toJson(),
    };
  }

  static int totalDiamonds(List<GiftModel> gifts) {
    return gifts.fold(0, (sum, gift) => sum + gift.diamonds);
  }
}

class Gift {
  final String id;
  final String name;
  final String category;
  final int diamonds;
  final int coinPrice;
  final String previewImage;
  final String svgaImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  Gift({
    required this.id,
    required this.name,
    required this.category,
    required this.diamonds,
    required this.coinPrice,
    required this.previewImage,
    required this.svgaImage,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      diamonds: json['diamonds'] as int,
      coinPrice: json['coinPrice'] as int,
      previewImage: json['previewImage'] as String,
      svgaImage: json['svgaImage'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      v: json['__v'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category,
      'diamonds': diamonds,
      'coinPrice': coinPrice,
      'previewImage': previewImage,
      'svgaImage': svgaImage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}
