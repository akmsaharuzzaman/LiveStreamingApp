import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/local_game_config.dart';

class LocalGameManager {
  static LocalGameManager? _instance;
  static LocalGameManager get instance => _instance ??= LocalGameManager._();

  LocalGameManager._();

  List<LocalGameConfig>? _games;

  /// Load all available local games from configuration
  Future<List<LocalGameConfig>> getAvailableGames() async {
    if (_games != null) return _games!;

    try {
      final configString = await rootBundle.loadString(
        'assets/games/games_config.json',
      );
      final configJson = json.decode(configString);

      _games = (configJson['games'] as List)
          .map((gameJson) => LocalGameConfig.fromJson(gameJson))
          .toList();

      print('📱 Loaded ${_games!.length} local games');
      return _games!;
    } catch (e) {
      print('❌ Failed to load games configuration: $e');
      return [];
    }
  }

  /// Get a specific game by ID
  Future<LocalGameConfig?> getGameById(String gameId) async {
    final games = await getAvailableGames();
    try {
      return games.firstWhere((game) => game.id == gameId);
    } catch (e) {
      print('❌ Game with ID "$gameId" not found');
      return null;
    }
  }

  /// Check if all required files exist for a game
  Future<bool> validateGameAssets(LocalGameConfig game) async {
    try {
      print('🔍 Validating assets for game: ${game.title}');
      for (final file in game.requiredFiles) {
        final assetPath = 'assets/games/${game.gamePath}/$file';
        print('   Checking: $assetPath');
        await rootBundle.load(assetPath);
        print('   ✅ Found: $file');
      }
      print('✅ All assets validated for game: ${game.title}');
      return true;
    } catch (e) {
      print('❌ Asset validation failed for ${game.title}: $e');
      return false;
    }
  }

  /// Get asset path for a game file
  String getAssetPath(LocalGameConfig game, String fileName) {
    return 'assets/games/${game.gamePath}/$fileName';
  }
}
