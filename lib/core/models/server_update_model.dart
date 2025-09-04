class ServerUpdateModel {
  final String version;
  final String releaseNote;
  final String downloadURL;

  ServerUpdateModel({
    required this.version,
    required this.releaseNote,
    required this.downloadURL,
  });

  factory ServerUpdateModel.fromJson(Map<String, dynamic> json) {
    return ServerUpdateModel(
      version: json['Version'] as String,
      releaseNote: json['Release_note'] as String,
      downloadURL: json['DownloadURL'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Version': version,
      'Release_note': releaseNote,
      'DownloadURL': downloadURL,
    };
  }

  @override
  String toString() {
    return 'ServerUpdateModel(version: $version, releaseNote: $releaseNote, downloadURL: $downloadURL)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerUpdateModel &&
        other.version == version &&
        other.releaseNote == releaseNote &&
        other.downloadURL == downloadURL;
  }

  @override
  int get hashCode {
    return version.hashCode ^ releaseNote.hashCode ^ downloadURL.hashCode;
  }
}
