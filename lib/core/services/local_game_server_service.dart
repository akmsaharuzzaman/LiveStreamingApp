import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
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
    if (_isRunning && _server != null) {
      print('🎮 Server already running at: $_serverUrl');
      return _serverUrl;
    }

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

      _currentGame = game;
      print('🎮 Loading game: ${game.title}');

      // Validate game assets
      final isValid = await gameManager.validateGameAssets(game);
      if (!isValid) {
        print('❌ Game assets validation failed');
        return null;
      }

      // Copy game files from assets to temporary directory
      print('📁 Copying game files...');
      final gameDirectory = await _copyGameFilesToTemp(game);
      print('✅ Game files copied to: ${gameDirectory.path}');

      // Create handler for serving static files
      final staticHandler = createStaticHandler(
        gameDirectory.path,
        defaultDocument: 'index.html',
        listDirectories: false,
      );

      // Create a debug handler
      final debugHandler = (Request request) {
        if (request.url.path == 'debug') {
          return Response.ok(
            'Server is running! Game files should be at /index.html\n'
            'Server URL: $_serverUrl\n'
            'Game directory: ${gameDirectory.path}',
          );
        }
        return Response.notFound('Debug endpoint not found');
      };

      final handler = Cascade().add(debugHandler).add(staticHandler).add((
        Request request,
      ) {
        print('❌ File not found: ${request.url.path}');
        return Response.notFound('File not found: ${request.url.path}');
      }).handler;

      // Add CORS headers for web compatibility
      final corsHandler = const Pipeline()
          .addMiddleware(_corsHeaders())
          .addHandler(handler);

      final handler2 = createStaticHandler(
        gameDirectory.path,
        defaultDocument: 'index.html',
        serveFilesOutsidePath: true,
      );

      // Start server on available port with fallback addresses
      try {
        // Try 127.0.0.1 first (most compatible with network security config)
        _server = await shelf_io.serve(
          handler2,
          InternetAddress.loopbackIPv4,
          8080,
        );
        // _server = await serve(corsHandler, InternetAddress.loopbackIPv4, 0);
        _serverUrl = 'http://127.0.0.1:${_server!.port}';
        print('🎮 Server bound to 127.0.0.1:${_server!.port}');
      } catch (e) {
        print('⚠️ Failed to bind to 127.0.0.1, trying any IPv4: $e');
        try {
          // Fallback to any available address
          _server = await serve(handler2, InternetAddress.anyIPv4, 0);
          // Get the actual IP address
          final networkInterfaces = await NetworkInterface.list();
          String? localIP;
          for (final interface in networkInterfaces) {
            for (final addr in interface.addresses) {
              if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
                localIP = addr.address;
                break;
              }
            }
            if (localIP != null) break;
          }
          _serverUrl = 'http://${localIP ?? '10.0.2.2'}:${_server!.port}';
          print('🎮 Server bound to any IPv4, using URL: $_serverUrl');
        } catch (e2) {
          print('❌ Failed to bind to any address: $e2');
          rethrow;
        }
      }

      _isRunning = true;

      print('🎮 Local game server started at: $_serverUrl');
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
  Future<Directory> _copyGameFilesToTemp(LocalGameConfig game) async {
    final tempDir = await getTemporaryDirectory();
    final gameDir = Directory(path.join(tempDir.path, 'local_game_${game.id}'));

    print('📁 Temp directory: ${tempDir.path}');
    print('📁 Game directory: ${gameDir.path}');

    // Create game directory if it doesn't exist
    if (!await gameDir.exists()) {
      await gameDir.create(recursive: true);
      print('✅ Created game directory');
    } else {
      print('📁 Game directory already exists');
    }

    final gameManager = LocalGameManager.instance;

    // Copy all required files for this game
    for (final fileName in game.requiredFiles) {
      try {
        final assetPath = gameManager.getAssetPath(game, fileName);
        final byteData = await rootBundle.load(assetPath);
        final file = File(path.join(gameDir.path, fileName));

        // Create directory if needed
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        print('✅ Copied $fileName to ${file.path}');
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

  /// Middleware to add CORS headers
  Middleware _corsHeaders() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);

        return response.change(
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            'Cross-Origin-Embedder-Policy': 'require-corp',
            'Cross-Origin-Opener-Policy': 'same-origin',
            ...response.headers,
          },
        );
      };
    };
  }
}
