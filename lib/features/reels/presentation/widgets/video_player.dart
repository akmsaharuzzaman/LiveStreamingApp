import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final bool isPlaying;

  const VideoPlayerWidget(
      {super.key, required this.url, required this.isPlaying});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController controller;
  late Duration _currentPosition = Duration.zero;
  late Duration _totalDuration = Duration.zero;

  bool _showOverlay = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.network(widget.url)
      ..setVolume(1.0)
      ..initialize().then((_) {
        setState(() {
          _totalDuration = controller.value.duration;
        });
        if (widget.isPlaying) controller.play();

        controller.addListener(() {
          setState(() {
            _currentPosition = controller.value.position;
          });
        });
      });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(":");
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !controller.value.isPlaying) {
      controller.play();
    } else if (!widget.isPlaying && controller.value.isPlaying) {
      controller.pause();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showOverlay = !_showOverlay;
          });
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
          setState(() {});
        },
        child: Stack(
          children: [
            controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                : const Center(child: CircularProgressIndicator()),
            _showControls
                ? Positioned(
                    bottom: 0, right: 0, left: 0, child: _buildControls())
                : const SizedBox.shrink(),
            if (_showOverlay)
              Center(
                child: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 70,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white, // Active track color
                      inactiveTrackColor:
                          Colors.grey[400], // Inactive track color
                      thumbColor: Colors.white, // Thumb color
                      overlayColor: Colors.white.withAlpha(32), // Overlay color
                      thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 6.0), // Thumb size
                      overlayShape: RoundSliderOverlayShape(
                          overlayRadius: 10.0), // Overlay size
                      trackHeight: 1, // Track height
                    ),
                    child: Slider(
                      value: _currentPosition.inSeconds.toDouble(),
                      min: 0,
                      max: _totalDuration.inSeconds.toDouble(),
                      onChanged: (value) {
                        setState(() {
                          _currentPosition = Duration(seconds: value.toInt());
                          controller.seekTo(_currentPosition);
                        });
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
