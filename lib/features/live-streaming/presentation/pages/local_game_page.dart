import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/services/local_game_server_service.dart';

class LocalGamePage extends StatefulWidget {
  final String gameTitle;
  final String? userId;

  const LocalGamePage({
    super.key,
    required this.gameTitle,
    this.userId,
  });

  @override
  State<LocalGamePage> createState() => _LocalGamePageState();
}

class _LocalGamePageState extends State<LocalGamePage> {
  late WebViewController _webViewController;
  String? _gameUrl;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeGame();
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
      final serverUrl = await LocalGameServerService.instance.startServer();

      if (serverUrl != null) {
        setState(() {
          _gameUrl = serverUrl;
          _isLoading = false;
        });

        _showSnackBar('✅ Game server started successfully!', Colors.green);
        _initializeWebView();
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

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onHttpError: (HttpResponseError error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'HTTP Error: ${error.response?.statusCode}';
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Web Resource Error: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_gameUrl!));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
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
              onPressed: _hasError ? _initializeGame : () {
                _webViewController.reload();
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
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading game...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
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
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
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
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
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
      return WebViewWidget(controller: _webViewController);
    }

    return const Center(
      child: Text(
        'Game not available',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    // Ensure server is stopped when widget is disposed
    LocalGameServerService.instance.stopServer();
    super.dispose();
  }
}
