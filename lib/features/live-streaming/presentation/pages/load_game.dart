import 'package:dlstarlive/core/services/local_game_server_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class LoadGame extends StatefulWidget {
  final String gameTitle;
  final String? gameId;
  final String? userId;
  const LoadGame({
    super.key,
    required this.gameTitle,
    this.gameId,
    this.userId,
  });

  @override
  State<LoadGame> createState() => _LoadGameState();
}

class _LoadGameState extends State<LoadGame> {
  late LocalGameServerService gameService;
  String? gameIP;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameService = LocalGameServerService.instance;
      startingServer();
    });
    super.initState();
  }

  startingServer() async {
    String? gameIP = await gameService.startServer(gameId: widget.gameId);
    if (gameIP != null) {
      print("Game server started at: ${gameService.serverUrl}");
      setState(() {
        gameIP = gameService.serverUrl;
      });
    } else {
      print("Failed to start game server.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("http://127.0.0.1:8080/index.html"),
        ),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
        ),
      ),
    );
  }
}
