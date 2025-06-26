import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../core/services/local_game_server_service.dart';

class LocalGamePage extends StatefulWidget {
  final String gameTitle;
  final String? gameId;
  final String? userId;

  const LocalGamePage({
    super.key,
    required this.gameTitle,
    this.gameId,
    this.userId,
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

  _startingServer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      _showSnackBar('🚀 Starting local game server...', Colors.blue);

      String? serverUrl = await gameService.startServer(gameId: widget.gameId);
      if (serverUrl != null) {
        print("Game server started at: ${gameService.serverUrl}");
        // _showSnackBar('✅ Game server started', Colors.green);
        setState(() {
          gameUrl = gameService.serverUrl;
          _isLoading = false;
        });
      } else {
        print("Failed to start game server.");
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
      print('🛑 Stopping game server...');
      await gameService.stopServer();
      // _showSnackBar('✅ Game server stopped', Colors.green);
      print('✅ Game server stopped');
    } catch (e) {
      // _showSnackBar('⚠️ Error stopping server: $e', Colors.red);
      print('⚠️ Error stopping server: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        // Fallback to print if ScaffoldMessenger is not available
        print('SnackBar: $message');
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
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            widget.gameTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _hasError
                  ? _startingServer
                  : () {
                      // Simple reload - just restart the server
                      _startingServer();
                    },
              tooltip: _hasError ? 'Retry' : 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeGame,
              tooltip: 'Close Game',
            ),
          ],
        ),
        body: _buildBody(),
      ),
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
        initialUrlRequest: URLRequest(url: WebUri(gameUrl!)),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            userAgent:
                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          ),
        ),
        onLoadStart: (controller, url) {
          print('📱 WebView started loading: $url');
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
        },
        onLoadStop: (controller, url) {
          print('✅ WebView finished loading: $url');
          setState(() {
            _isLoading = false;
          });
        },
        onLoadError: (controller, url, code, message) {
          print('❌ Load Error: $code - $message');
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
