import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/simple_auth_service.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/story_response_model.dart';

class StoryViewerPage extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final String? currentUserId; // Add current user ID parameter
  final VoidCallback? onStoriesUpdated; // Callback to notify parent of updates

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.currentUserId,
    this.onStoriesUpdated,
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
  String? _currentUserId;
  bool _isPaused = false; // Track if story is paused
  bool _hasInteracted = false; // Track if user has viewed/reacted to stories

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

    // Add a smooth animation curve for better visual experience
    _progressController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    }); // Initialize services
    final apiService = ApiService.instance;
    final authService = AuthService();
    _postService = PostService(apiService, authService);

    // Set current user ID from parameter
    _currentUserId = widget.currentUserId;

    _startStoryProgress();
  }

  @override
  void dispose() {
    // Notify parent if user has interacted with stories
    if (_hasInteracted && widget.onStoriesUpdated != null) {
      // Use addPostFrameCallback to ensure the callback runs after dispose
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onStoriesUpdated!();
      });
    }

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

  void _pauseStoryProgress() {
    if (_progressController.isAnimating) {
      _progressController.stop();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resumeStoryProgress() {
    if (!_progressController.isAnimating && _progressController.value < 1.0) {
      _progressController.forward();
    }
    setState(() {
      _isPaused = false;
    });
  }

  void _nextStory() {
    // Mark that user has interacted (viewed stories)
    _hasInteracted = true;

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
    // Mark that user has interacted (viewed stories)
    _hasInteracted = true;

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
        // Update story with new reaction data, preserving user info
        final currentStory = _stories[_currentIndex];
        final reactionData = data['result'];

        // Create new reaction object
        final newReaction = StoryReaction(reactionType: reactionType);

        // Use copyWith to preserve existing user info
        final updatedStory = currentStory.copyWith(
          reactionCount:
              reactionData['reactionCount'] ?? currentStory.reactionCount,
          myReaction: newReaction,
        );

        print('Updated Story: ${updatedStory.toJson()}');
        setState(() {
          _stories[_currentIndex] = updatedStory;
        });

        // Show reaction feedback
        _showReactionFeedback(reactionType);

        // Mark that user has interacted (reacted to stories)
        _hasInteracted = true;
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
      case 'care':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      default:
        return '👍';
    }
  }

  Future<void> _deleteCurrentStory() async {
    if (_isLoading) return;

    final currentStory = _stories[_currentIndex];

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Story',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this story? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _postService.deleteStory(currentStory.id);

    result.when(
      success: (data) {
        // Remove story from list
        setState(() {
          _stories.removeAt(_currentIndex);
        });

        // Mark that user has interacted (deleted story)
        _hasInteracted = true;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to next story or close if this was the last one
        if (_stories.isEmpty) {
          Navigator.of(context).pop();
        } else {
          if (_currentIndex >= _stories.length) {
            _currentIndex = _stories.length - 1;
          }
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _startStoryProgress();
        }
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete story: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  bool _isCurrentUserStory() {
    if (_currentUserId == null || _stories.isEmpty) return false;
    final currentStory = _stories[_currentIndex];
    return currentStory.ownerId == _currentUserId;
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
        onLongPressStart: (_) {
          // Pause story progress when user holds down
          _pauseStoryProgress();
        },
        onLongPressEnd: (_) {
          // Resume story progress when user releases hold
          _resumeStoryProgress();
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
                // Mark interaction when user manually swipes between stories
                _hasInteracted = true;
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
                      height: 4, // Increased from 3 to 4 for better visibility
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
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
                  _buildReactionButton('sad', '😢'),
                  const SizedBox(height: 15),
                  _buildReactionButton('angry', '😠'),
                  const SizedBox(height: 15),
                  _buildReactionButton('care', '😊'),
                ],
              ),
            ),

            // Delete Button (for current user's story)
            if (_isCurrentUserStory())
              Positioned(
                bottom: 100,
                left: 20,
                child: GestureDetector(
                  onTap: _deleteCurrentStory,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

            // Pause Indicator
            if (_isPaused)
              const Center(
                child: Icon(
                  Icons.pause_circle_filled,
                  color: Colors.white,
                  size: 80,
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
