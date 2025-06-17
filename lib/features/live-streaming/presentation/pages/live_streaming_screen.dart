import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:streaming_djlive/core/utils/permission_helper.dart';
import 'package:streaming_djlive/features/live-streaming/data/models/chat_message.dart';

class LiveStreamingScreen extends StatefulWidget {
  final String streamId;
  final String thumbnailPath;
  final String title;
  final bool isBroadCaster;
  final String userName;
  const LiveStreamingScreen({
    super.key,
    required this.streamId,
    required this.thumbnailPath,
    required this.title,
    required this.isBroadCaster,
    required this.userName,
  });
  static const String routeName = '/live_stream';

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  final List<int> _remoteUsers = [];
  bool _muted = false;
  bool _cameraEnabled = true;
  int _viewerCount = 0;
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  @override
  void initState() {
    initAgora();
    _setupChatListener();
    super.initState();
  }

  void _setupChatListener() {
    // Listen to chat messages for this stream
    // Socket.getChatMessages(widget.streamId).listen((messages) {
    //   setState(() {
    //     _chatMessages.clear();
    //     _chatMessages.addAll(messages);
    //   });
    // });
  }

  Future<void> initAgora() async {
    // retrieve permissions
    PermissionHelper.hasLiveStreamPermissions().then((hasPermissions) {
      if (!hasPermissions) {
        PermissionHelper.requestLiveStreamPermissions().then((granted) {
          if (!granted) {
            if (mounted) {
              PermissionHelper.showPermissionDialog(context);
            }
          }
        });
      }
    });

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: dotenv.env['AGORA_APP_ID'] ?? '',
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
            _remoteUid = connection.localUid;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            _remoteUsers.add(remoteUid);
            _viewerCount = _remoteUsers.length;
          });

          // Update viewer count in Firestore
          if (widget.isBroadCaster) {
            // _firestoreService.updateViewerCount(widget.streamId, _viewerCount);
          }
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("remote user $remoteUid left channel");
              setState(() {
                _remoteUid = null;
                _remoteUsers.remove(remoteUid);
                _viewerCount = _remoteUsers.length;
              });

              // Update viewer count in Firestore
              if (widget.isBroadCaster) {
                // _firestoreService.updateViewerCount(
                //   widget.streamId,
                //   _viewerCount,
                // );
              }
            },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
            '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token',
          );
        },
      ),
    );

    await _engine.setClientRole(
      role: widget.isBroadCaster
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: dotenv.env['AGORA_TOKEN'] ?? '',
      channelId: dotenv.env['DEFAULT_CHANNEL'] ?? widget.streamId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    super.dispose();

    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  // Toggle microphone
  void _toggleMute() async {
    await _engine.muteLocalAudioStream(!_muted);
    setState(() {
      _muted = !_muted;
    });
  }

  // Toggle camera
  void _toggleCamera() async {
    await _engine.muteLocalVideoStream(!_cameraEnabled);
    setState(() {
      _cameraEnabled = !_cameraEnabled;
    });
  }

  // Switch camera
  void _switchCamera() async {
    await _engine.switchCamera();
  }

  // End live stream
  void _endLiveStream() async {
    try {
      if (widget.isBroadCaster) {
        // Update stream status to not live
        // await _firestoreService.updateLiveStream(widget.streamId, {
        //   'isLive': false,
        // });
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Still navigate back even if update fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // Send chat message
  void _sendChatMessage() async {
    if (_chatController.text.trim().isNotEmpty) {
      try {
        // final authState = context.read<AuthCubit>().state;
        if (true) {
          final message = ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            message: _chatController.text.trim(),
            userId: '',
            userName: 'Anonymous',
            userProfilePic: '',
            timestamp: DateTime.now(),
            streamId: widget.streamId,
          );

          try {
            // Send message to Firestore
            // await _firestoreService.sendChatMessage(message);
            setState(() {
              _chatMessages.add(message);
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to send message: $e')),
              );
            }
          }
          _chatController.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video view
          _buildVideoView(),

          // Top overlay with stream info
          _buildTopOverlay(),

          // Bottom controls overlay
          _buildBottomControls(),

          // Chat overlay (only for broadcaster)
          if (widget.isBroadCaster || !widget.isBroadCaster)
            _buildChatOverlay(),
        ],
      ),
    );
  }

  // Main video view
  Widget _buildVideoView() {
    if (widget.isBroadCaster) {
      // Show local video for broadcaster
      return _localUserJoined
          ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      // Show remote video for viewers
      return _remoteVideo();
    }
  }

  // Top overlay with stream info
  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: .7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Stream title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LIVE | $_viewerCount viewers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Back button
            IconButton(
              onPressed: _endLiveStream,
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom controls for broadcaster
  Widget _buildBottomControls() {
    if (!widget.isBroadCaster) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: .7), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _muted ? Icons.mic_off : Icons.mic,
                color: _muted ? Colors.red : Colors.white,
                size: 28,
              ),
            ),

            // Camera toggle
            IconButton(
              onPressed: _toggleCamera,
              icon: Icon(
                _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                color: _cameraEnabled ? Colors.white : Colors.red,
                size: 28,
              ),
            ),

            // Switch camera
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 28,
              ),
            ),

            // End stream
            IconButton(
              onPressed: _endLiveStream,
              icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  // Chat overlay
  Widget _buildChatOverlay() {
    return Positioned(
      right: 16,
      top: 500,
      bottom: 120,
      width: MediaQuery.of(context).size.width * .92,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Chat header
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: .8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Chat messages
            Expanded(
              child: ListView.builder(
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatMessages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${message.userName}: ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: message.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Chat input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendChatMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendChatMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: "default_channel"),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }
}
