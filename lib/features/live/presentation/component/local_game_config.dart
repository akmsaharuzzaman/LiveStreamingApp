class LocalGameConfig {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final String gamePath; // Folder name in assets/games/
  final List<String> requiredFiles;
  final Map<String, dynamic>? gameParameters;

  const LocalGameConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.gamePath,
    required this.requiredFiles,
    this.gameParameters,
  });

  factory LocalGameConfig.fromJson(Map<String, dynamic> json) {
    return LocalGameConfig(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconPath: json['iconPath'],
      gamePath: json['gamePath'],
      requiredFiles: List<String>.from(json['requiredFiles']),
      gameParameters: json['gameParameters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'gamePath': gamePath,
      'requiredFiles': requiredFiles,
      'gameParameters': gameParameters,
    };
  }
}
