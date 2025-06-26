import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as path;

class LocalGameServerService {
  static LocalGameServerService? _instance;
  static LocalGameServerService get instance =>
      _instance ??= LocalGameServerService._();

  LocalGameServerService._();

  HttpServer? _server;
  String? _serverUrl;
  bool _isRunning = false;

  /// Start the local server to serve Unity WebGL game
  Future<String?> startServer() async {
    if (_isRunning && _server != null) {
      print('🎮 Server already running at: $_serverUrl');
      return _serverUrl;
    }

    try {
      print('🚀 Starting local game server...');

      // Copy game files from assets to temporary directory
      print('📁 Copying game files...');
      final gameDirectory = await _copyGameFilesToTemp();
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

      // Start server on available port with fallback addresses
      try {
        // Try 127.0.0.1 first (most compatible with network security config)
        _server = await serve(corsHandler, InternetAddress.loopbackIPv4, 0);
        _serverUrl = 'http://127.0.0.1:${_server!.port}';
        print('🎮 Server bound to 127.0.0.1:${_server!.port}');
      } catch (e) {
        print('⚠️ Failed to bind to 127.0.0.1, trying any IPv4: $e');
        try {
          // Fallback to any available address
          _server = await serve(corsHandler, InternetAddress.anyIPv4, 0);
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
  Future<Directory> _copyGameFilesToTemp() async {
    final tempDir = await getTemporaryDirectory();
    final gameDir = Directory(path.join(tempDir.path, 'unityweb_game'));

    print('📁 Temp directory: ${tempDir.path}');
    print('📁 Game directory: ${gameDir.path}');

    // Create game directory if it doesn't exist
    if (!await gameDir.exists()) {
      await gameDir.create(recursive: true);
      print('✅ Created game directory');
    } else {
      print('📁 Game directory already exists');
    }

    // List of files to copy from assets/unityweb/
    final filesToCopy = ['index.html', 'bg.jpg', 'game-icon.png'];

    // Copy individual files
    for (final fileName in filesToCopy) {
      try {
        final assetPath = 'assets/unityweb/$fileName';
        final byteData = await rootBundle.load(assetPath);
        final file = File(path.join(gameDir.path, fileName));
        await file.writeAsBytes(byteData.buffer.asUint8List());
        print('✅ Copied $fileName to ${file.path}');
      } catch (e) {
        print('⚠️ Failed to copy $fileName: $e');
      }
    }

    // Copy Build directory recursively
    await _copyBuildDirectory(gameDir);

    return gameDir;
  }

  /// Copy Build directory from assets
  Future<void> _copyBuildDirectory(Directory gameDir) async {
    final buildDir = Directory(path.join(gameDir.path, 'Build'));
    if (!await buildDir.exists()) {
      await buildDir.create(recursive: true);
    }

    // List of typical Unity WebGL build files
    final buildFiles = [
      'Build/fruit-loops.data',
      'Build/fruit-loops.framework.js',
      'Build/fruit-loops.loader.js',
      'Build/fruit-loops.wasm',
      'Build/fruit-loops.data.unityweb',
      'Build/fruit-loops.framework.js.unityweb',
      'Build/fruit-loops.loader.js.unityweb',
      'Build/fruit-loops.wasm.unityweb',
    ];

    // Try to copy build files (some might not exist depending on Unity build)
    for (final buildFile in buildFiles) {
      try {
        final assetPath = 'assets/unityweb/$buildFile';
        final byteData = await rootBundle.load(assetPath);
        final file = File(path.join(gameDir.path, buildFile));

        // Create directory if needed
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        print('✅ Copied $buildFile');
      } catch (e) {
        // Build files might have different names, so we skip missing ones
        print('⚠️ Skipped $buildFile (not found): $e');
      }
    }

    // Try to copy any files that exist in the Build folder
    try {
      // Get list of all asset files
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifest = manifestContent.split('"');

      for (final asset in manifest) {
        if (asset.startsWith('assets/unityweb/Build/')) {
          try {
            final relativePath = asset.substring('assets/unityweb/'.length);
            final byteData = await rootBundle.load(asset);
            final file = File(path.join(gameDir.path, relativePath));
            await file.parent.create(recursive: true);
            await file.writeAsBytes(byteData.buffer.asUint8List());
            print('✅ Copied build asset: $relativePath');
          } catch (e) {
            print('⚠️ Failed to copy build asset $asset: $e');
          }
        }
      }
    } catch (e) {
      print('⚠️ Could not read asset manifest: $e');
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
