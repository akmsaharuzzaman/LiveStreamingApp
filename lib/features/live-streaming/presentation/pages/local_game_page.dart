import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
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
  InAppWebViewController? _webViewController;
  String? _gameUrl;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure the widget is fully built before showing SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Start local server
      _showSnackBar('🚀 Starting local game server...', Colors.blue);
      final serverUrl = await LocalGameServerService.instance.startServer(
        gameId: widget.gameId,
      );

      if (serverUrl != null) {
        print('🎮 Game URL: $serverUrl');
        _showSnackBar('✅ Game server started at $serverUrl', Colors.green);

        // Test server connectivity before loading WebView
        final isConnectable = await _testServerConnectivity(serverUrl);
        if (isConnectable) {
          setState(() {
            _gameUrl = serverUrl;
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Server started but not accessible from Android WebView';
            _isLoading = false;
          });
          _showSnackBar('❌ Server connectivity test failed', Colors.red);
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to start local game server';
          _isLoading = false;
        });
        _showSnackBar('❌ Failed to start game server', Colors.red);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing game: $e';
        _isLoading = false;
      });
      _showSnackBar('❌ Game initialization failed', Colors.red);
    }
  }

  /// Test server connectivity before loading in WebView
  Future<bool> _testServerConnectivity(String url) async {
    try {
      final client = HttpClient();

      // Test both debug endpoint and main page
      final debugUrl = '$url/debug';
      final mainUrl = url;

      print('🔍 Testing server connectivity...');
      print('   Debug URL: $debugUrl');
      print('   Main URL: $mainUrl');

      // Test debug endpoint first
      try {
        final debugRequest = await client.getUrl(Uri.parse(debugUrl));
        final debugResponse = await debugRequest.close();

        if (debugResponse.statusCode == 200) {
          print('✅ Debug endpoint accessible');

          // Now test main page
          final mainRequest = await client.getUrl(Uri.parse(mainUrl));
          final mainResponse = await mainRequest.close();

          if (mainResponse.statusCode == 200) {
            print('✅ Main page accessible');
            return true;
          } else {
            print(
              '⚠️ Main page responded with status: ${mainResponse.statusCode}',
            );
            return false;
          }
        } else {
          print(
            '⚠️ Debug endpoint responded with status: ${debugResponse.statusCode}',
          );
          return false;
        }
      } catch (e) {
        print('❌ Error testing endpoints: $e');
        return false;
      }
    } catch (e) {
      print('❌ Server connectivity test failed: $e');
      return false;
    }
  }

  Future<void> _closeGame() async {
    try {
      _showSnackBar('🛑 Stopping game server...', Colors.orange);
      await LocalGameServerService.instance.stopServer();
      _showSnackBar('✅ Game server stopped', Colors.green);
    } catch (e) {
      _showSnackBar('⚠️ Error stopping server: $e', Colors.red);
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
          await LocalGameServerService.instance.stopServer();
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
                  ? _initializeGame
                  : () {
                      _webViewController?.reload();
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
    if (_isLoading && _gameUrl == null) {
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
              onPressed: _initializeGame,
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

    if (_gameUrl != null) {
      return Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_gameUrl!)),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
              ),
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
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
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading game...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return const Center(
      child: Text('Game not available', style: TextStyle(color: Colors.white)),
    );
  }

  @override
  void dispose() {
    // Ensure server is stopped when widget is disposed
    LocalGameServerService.instance.stopServer();
    super.dispose();
  }
}
