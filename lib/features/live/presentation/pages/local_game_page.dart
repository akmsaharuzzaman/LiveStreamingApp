import 'package:dlstarlive/features/live/presentation/component/local_game_server_service.dart'
    show LocalGameServerService;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class LocalGamePage extends StatefulWidget {
  final String gameTitle;
  final String? gameId;
  final String? userId;
  final VoidCallback? onGameClosed;

  const LocalGamePage({
    super.key,
    required this.gameTitle,
    this.gameId,
    this.userId,
    this.onGameClosed,
  });

  @override
  State<LocalGamePage> createState() => _LocalGamePageState();
}

class _LocalGamePageState extends State<LocalGamePage> {
  late LocalGameServerService gameService;
  String? gameUrl;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameService = LocalGameServerService.instance;
      _startingServer();
    });
  }

  void _startingServer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // _showSnackBar('🚀 Starting local game server...', Colors.blue);
      debugPrint('🚀 Starting local game server...');

      String? serverUrl = await gameService.startServer(gameId: widget.gameId);
      if (serverUrl != null) {
        debugPrint("Game server started at: ${gameService.serverUrl}");
        // _showSnackBar('✅ Game server started', Colors.green);
        setState(() {
          gameUrl = gameService.serverUrl;
          _isLoading = false;
        });
      } else {
        debugPrint("Failed to start game server.");
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to start local game server';
          _isLoading = false;
        });
        // _showSnackBar('❌ Failed to start game server', Colors.red);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing game: $e';
        _isLoading = false;
      });
      // _showSnackBar('❌ Game initialization failed', Colors.red);
    }
  }

  Future<void> _closeGame() async {
    try {
      // _showSnackBar('🛑 Stopping game server...', Colors.orange);
      debugPrint('🛑 Stopping game server...');
      await gameService.stopServer();
      // _showSnackBar('✅ Game server stopped', Colors.green);
      debugPrint('✅ Game server stopped');
    } catch (e) {
      // _showSnackBar('⚠️ Error stopping server: $e', Colors.red);
      debugPrint('⚠️ Error stopping server: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          // Stop the server when page is closed
          await gameService.stopServer();
        }
      },
      child: Scaffold(backgroundColor: Colors.black, body: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading && gameUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Starting game server...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load game',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startingServer,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (gameUrl != null) {
      return InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(
            "${gameUrl!}/index.html?user_id=${widget.userId}&baseurl=http://147.93.103.135:8000/api/games",
          ),
        ),
        // ignore: deprecated_member_use
        initialOptions: InAppWebViewGroupOptions(
          // ignore: deprecated_member_use
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            userAgent:
                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          ),
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: "GoHomeFromUnity",
            callback: (args) {
              _closeGame();
              widget.onGameClosed?.call();
              return Future.value("Game closed from Unity");
            },
          );
        },
        onLoadStart: (controller, url) {
          debugPrint('📱 WebView started loading: $url');
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
        },
        onLoadStop: (controller, url) {
          debugPrint('✅ WebView finished loading: $url');
          setState(() {
            _isLoading = false;
          });
        },
        // ignore: deprecated_member_use
        onLoadError: (controller, url, code, message) {
          debugPrint('❌ Load Error: $code - $message');
          setState(() {
            _hasError = true;
            _errorMessage = 'Load Error: $message';
            _isLoading = false;
          });
        },
      );
    }

    return const Center(
      child: Text('Game not available', style: TextStyle(color: Colors.white)),
    );
  }

  @override
  void dispose() {
    // Ensure server is stopped when widget is disposed
    gameService.stopServer();
    super.dispose();
  }
}
