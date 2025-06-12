// ignore_for_file: public_member_api_docs, sort_constructors_first

// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

class LiveStreamModel {
  final int peopleParticipant;
  final int type;
  final String urlToImage;
  LiveStreamModel({
    required this.peopleParticipant,
    required this.type,
    required this.urlToImage,
  });

  LiveStreamModel copyWith({
    int? peopleParticipant,
    int? type,
    String? urlToImage,
  }) {
    return LiveStreamModel(
      peopleParticipant: peopleParticipant ?? this.peopleParticipant,
      type: type ?? this.type,
      urlToImage: urlToImage ?? this.urlToImage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'peopleParticipant': peopleParticipant,
      'type': type,
      'urlToImage': urlToImage,
    };
  }

  factory LiveStreamModel.fromMap(Map<String, dynamic> map) {
    return LiveStreamModel(
      peopleParticipant: map['peopleParticipant'] as int,
      type: map['type'] as int,
      urlToImage: map['urlToImage'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory LiveStreamModel.fromJson(String source) =>
      LiveStreamModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'LiveStreamModel(peopleParticipant: $peopleParticipant, type: $type, urlToImage: $urlToImage)';

  @override
  bool operator ==(covariant LiveStreamModel other) {
    if (identical(this, other)) return true;

    return other.peopleParticipant == peopleParticipant &&
        other.type == type &&
        other.urlToImage == urlToImage;
  }

  @override
  int get hashCode =>
      peopleParticipant.hashCode ^ type.hashCode ^ urlToImage.hashCode;

  String get getTitleType {
    switch (type) {
      case 1:
        return 'Video';
      case 2:
        return 'Party';
      case 3:
        return 'PK';
    }
    return '';
  }

  Color get getColorType {
    switch (type) {
      case 1:
        return Colors.pink;
      case 2:
        return Colors.purple;
      case 3:
        return Colors.deepOrange;
    }
    return Colors.redAccent;
  }
}

List<LiveStreamModel> listLiveStreamFake = [
  LiveStreamModel(peopleParticipant: 910, type: 1, urlToImage: urlImageGame),
  LiveStreamModel(peopleParticipant: 910, type: 2, urlToImage: urlImageReview),
  LiveStreamModel(peopleParticipant: 910, type: 3, urlToImage: urlImageMusic),
  LiveStreamModel(peopleParticipant: 910, type: 2, urlToImage: urlImageReview),
  LiveStreamModel(peopleParticipant: 910, type: 3, urlToImage: urlImageMusic),
  LiveStreamModel(peopleParticipant: 910, type: 2, urlToImage: urlImageReview),
  LiveStreamModel(peopleParticipant: 910, type: 3, urlToImage: urlImageMusic),
  LiveStreamModel(peopleParticipant: 910, type: 1, urlToImage: urlImageGame),
  LiveStreamModel(peopleParticipant: 910, type: 2, urlToImage: urlImageReview),
  LiveStreamModel(peopleParticipant: 910, type: 1, urlToImage: urlImageGame),
  LiveStreamModel(peopleParticipant: 910, type: 2, urlToImage: urlImageReview),
];

String urlImageGame =
    'https://parsefiles.back4app.com/SM60vnNNpjvoH6PA6ljZAa6IyAYVb1oWVVid8G4A/b5cad4e8f706d824e04b44f25e20905e_live_photo_42_710.jpg';
String urlImageReview =
    'https://parsefiles.back4app.com/SM60vnNNpjvoH6PA6ljZAa6IyAYVb1oWVVid8G4A/64ed854a7d299411dd567bbb5a5eb301_user_pic_0_14_143.jpg';
String urlImageMusic =
    'https://parsefiles.back4app.com/SM60vnNNpjvoH6PA6ljZAa6IyAYVb1oWVVid8G4A/5611a0edc59259216dc6c08c0fe1464d_live_photo_48_241.jpg';
