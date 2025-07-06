import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as path;
import '../models/local_game_config.dart';
import 'local_game_manager.dart';

class LocalGameServerService {
  static LocalGameServerService? _instance;
  static LocalGameServerService get instance =>
      _instance ??= LocalGameServerService._();

  LocalGameServerService._();

  HttpServer? _server;
  String? _serverUrl;
  bool _isRunning = false;
  LocalGameConfig? _currentGame;

  /// Start the local server to serve a specific Unity WebGL game
  Future<String?> startServer({String? gameId}) async {
    try {
      print('🚀 Starting local game server...');

      // Get game configuration
      final gameManager = LocalGameManager.instance;
      final game = gameId != null
          ? await gameManager.getGameById(gameId)
          : (await gameManager.getAvailableGames()).first;

      if (game == null) {
        print('❌ Game not found: $gameId');
        return null;
      }

      // Stop existing server if running and starting a different game
      if (_isRunning && _currentGame?.id != game.id) {
        print('🔄 Switching from ${_currentGame?.title} to ${game.title}');
        await stopServer();
      }

      // If server is running with the same game, return existing URL
      if (_isRunning && _server != null && _currentGame?.id == game.id) {
        print('🎮 Server already running with ${game.title} at: $_serverUrl');
        return _serverUrl;
      }

      _currentGame = game;
      print('🎮 Loading game: ${game.title}');

      // Validate game assets
      final isValid = await gameManager.validateGameAssets(game);
      if (!isValid) {
        print('❌ Game assets validation failed');
        return null;
      }

      // Copy game files to static directory (delete previous files first)
      print('📁 Preparing game files...');
      final gameDirectory = await _prepareGameFiles(game);
      print('✅ Game files prepared at: ${gameDirectory.path}');

      // Create handler for serving static files
      final staticHandler = createStaticHandler(
        gameDirectory.path,
        defaultDocument: 'index.html',
        serveFilesOutsidePath: true,
      );

      // Start server on fixed port 8080
      _server = await shelf_io.serve(
        staticHandler,
        InternetAddress.loopbackIPv4,
        8080,
      );

      _serverUrl = 'http://127.0.0.1:8080';
      _isRunning = true;

      print('🎮 Local game server started at: $_serverUrl');
      print('🎮 Serving game: ${game.title}');
      return _serverUrl;
    } catch (e, stackTrace) {
      print('❌ Failed to start local game server: $e');
      print('❌ Stack trace: $stackTrace');
      _isRunning = false;
      _server = null;
      _serverUrl = null;
      return null;
    }
  }

  /// Stop the local server
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _serverUrl = null;
      _isRunning = false;
      print('🛑 Local game server stopped');
    }
  }

  /// Check if server is running
  bool get isRunning => _isRunning;

  /// Get current server URL
  String? get serverUrl => _serverUrl;

  /// Copy game files from assets to temporary directory
  Future<Directory> _prepareGameFiles(LocalGameConfig game) async {
    // Use Documents directory instead of temp for persistence across app launches
    final dir = await getApplicationDocumentsDirectory();
    final gameDir = Directory('${dir.path}/unityweb');

    // Delete existing files if directory exists (clean slate for new game)
    if (gameDir.existsSync()) {
      print('🗑️ Deleting previous game files...');
      await gameDir.delete(recursive: true);
    }

    // Create the directory
    gameDir.createSync(recursive: true);
    print('📁 Created clean game directory: ${gameDir.path}');

    final gameManager = LocalGameManager.instance;

    // Copy all required files for this game
    for (final fileName in game.requiredFiles) {
      try {
        final assetPath = gameManager.getAssetPath(game, fileName);
        final byteData = await rootBundle.load(assetPath);
        final file = File(path.join(gameDir.path, fileName));

        // Create subdirectories if needed (like Build/)
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        print('✅ Copied $fileName');
      } catch (e) {
        print('⚠️ Failed to copy $fileName: $e');
      }
    }

    // Debug: List all files that were copied
    await _listCopiedFiles(gameDir);

    return gameDir;
  }

  /// Debug function to list all copied files
  Future<void> _listCopiedFiles(Directory gameDir) async {
    try {
      print('📋 Listing all copied files:');
      final files = await gameDir.list(recursive: true).toList();
      for (final file in files) {
        if (file is File) {
          final relativePath = file.path.substring(gameDir.path.length + 1);
          final size = await file.length();
          print('   📄 $relativePath (${(size / 1024).toStringAsFixed(1)} KB)');
        }
      }
    } catch (e) {
      print('⚠️ Could not list copied files: $e');
    }
  }
}
