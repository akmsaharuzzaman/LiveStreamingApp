import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/simple_auth_service.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/story_response_model.dart';

class StoryViewerPage extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late PostService _postService;

  int _currentIndex = 0;
  List<StoryModel> _stories = [];
  bool _isLoading = false;

  // Story progress duration (5 seconds per story)
  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _stories = List.from(widget.stories);
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );

    // Initialize services
    final apiService = ApiService.instance;
    final authService = AuthService();
    _postService = PostService(apiService, authService);

    _startStoryProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startStoryProgress() {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted) {
        _nextStory();
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      _currentIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryProgress();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryProgress();
    }
  }

  Future<void> _reactToStory(String reactionType) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final currentStory = _stories[_currentIndex];

    final result = await _postService.reactToStory(
      storyId: currentStory.id,
      reactionType: reactionType,
    );

    result.when(
      success: (data) {
        // Update story with new reaction data
        final updatedStory = StoryModel.fromJson(data['result']);
        setState(() {
          _stories[_currentIndex] = updatedStory;
        });

        // Show reaction feedback
        _showReactionFeedback(reactionType);
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _showReactionFeedback(String reactionType) {
    // Show animated reaction icon
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: MediaQuery.of(context).size.width * 0.4,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.5, end: 2.0),
            onEnd: () => overlayEntry.remove(),
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: (2.0 - scale) / 1.5,
                child: Text(
                  _getReactionEmoji(reactionType),
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  String _getReactionEmoji(String reactionType) {
    switch (reactionType.toLowerCase()) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'haha':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      default:
        return '👍';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // Story Content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _startStoryProgress();
              },
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final story = _stories[index];
                return _buildStoryContent(story);
              },
            ),

            // Progress Indicators
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(_stories.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: LinearProgressIndicator(
                        value: index == _currentIndex
                            ? _progressController.value
                            : index < _currentIndex
                            ? 1.0
                            : 0.0,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 30,
              right: 15,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),

            // Reaction Buttons
            Positioned(
              bottom: 100,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildReactionButton('like', '👍'),
                  const SizedBox(height: 15),
                  _buildReactionButton('love', '❤️'),
                  const SizedBox(height: 15),
                  _buildReactionButton('haha', '😂'),
                  const SizedBox(height: 15),
                  _buildReactionButton('wow', '😮'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Story Image/Video
        CachedNetworkImage(
          imageUrl: story.mediaUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.error, color: Colors.white, size: 50),
            ),
          ),
        ),

        // Story Info
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 15,
          right: 80,
          child: Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundImage: story.userInfo?.avatar?.url != null
                    ? CachedNetworkImageProvider(story.userInfo!.avatar!.url)
                    : null,
                backgroundColor: Colors.grey[600],
                child: story.userInfo?.avatar?.url == null
                    ? Text(
                        story.userInfo?.name.substring(0, 1).toUpperCase() ??
                            '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.userInfo?.name ?? 'Unknown User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(story.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reaction Count
        if (story.reactionCount > 0)
          Positioned(
            bottom: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${story.reactionCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReactionButton(String reactionType, String emoji) {
    final currentStory = _stories[_currentIndex];
    final isMyReaction = currentStory.myReaction?.reactionType == reactionType;

    return GestureDetector(
      onTap: _isLoading ? null : () => _reactToStory(reactionType),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isMyReaction
              ? Colors.red.withOpacity(0.8)
              : Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: isMyReaction ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
      ),
    );
  }

  String _formatTimeAgo(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return '';
    }
  }
}
