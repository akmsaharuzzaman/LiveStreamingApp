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

// Helper class to group stories by user
class UserStoryGroup {
  final String userId;
  final String userName;
  final String? userAvatar;
  final List<StoryModel> stories;

  UserStoryGroup({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.stories,
  });
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  late PostService _postService;

  // Facebook-style grouped viewing state
  List<UserStoryGroup> _userGroups = [];
  int _currentGroupIndex = 0; // Current user group
  int _currentStoryIndex = 0; // Current story within the group
  List<StoryModel> _stories = []; // Flattened list for backward compatibility

  bool _isLoading = false;
  String? _currentUserId;
  bool _isPaused = false; // Track if story is paused
  bool _hasInteracted = false; // Track if user has viewed/reacted to stories
  bool _isAnimating = false; // Track if slide animation is in progress

  // Story progress duration (5 seconds per story)
  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    // Group stories by user (Facebook-style)
    _userGroups = _groupStoriesByUser(widget.stories);
    _stories = List.from(
      widget.stories,
    ); // Keep flattened list for backward compatibility

    // Find initial group and story indices
    _findInitialIndices(widget.initialIndex);

    _pageController = PageController(
      initialPage: 0,
    ); // Always start from page 0 since we're managing groups
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );

    // Initialize slide animation controller for smooth transitions
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create slide animation with ease curve
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // Add a smooth animation curve for better visual experience
    _progressController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Initialize services
    final apiService = ApiService.instance;
    final authService = AuthService();
    _postService = PostService(apiService, authService);

    // Set current user ID from parameter
    _currentUserId = widget.currentUserId;

    _startStoryProgress();
  }

  // Group stories by user ID for Facebook-style viewing
  List<UserStoryGroup> _groupStoriesByUser(List<StoryModel> stories) {
    final Map<String, List<StoryModel>> groupedMap = {};

    for (final story in stories) {
      final userId = story.ownerId;
      if (!groupedMap.containsKey(userId)) {
        groupedMap[userId] = [];
      }
      groupedMap[userId]!.add(story);
    }

    return groupedMap.entries.map((entry) {
      final userId = entry.key;
      final userStories = entry.value;

      // Get user info from first story
      final firstStory = userStories.first;
      return UserStoryGroup(
        userId: userId,
        userName: firstStory.userInfo?.name ?? 'Unknown User',
        userAvatar: firstStory.userInfo?.avatar?.url,
        stories: userStories,
      );
    }).toList();
  }

  // Find which group and story index to start from based on initial index
  void _findInitialIndices(int initialGlobalIndex) {
    int globalIndex = 0;

    for (int groupIndex = 0; groupIndex < _userGroups.length; groupIndex++) {
      final group = _userGroups[groupIndex];

      for (
        int storyIndex = 0;
        storyIndex < group.stories.length;
        storyIndex++
      ) {
        if (globalIndex == initialGlobalIndex) {
          _currentGroupIndex = groupIndex;
          _currentStoryIndex = storyIndex;
          return;
        }
        globalIndex++;
      }
    }

    // Fallback if not found
    _currentGroupIndex = 0;
    _currentStoryIndex = 0;
  }

  // Get current story being viewed
  StoryModel get _currentStory {
    if (_userGroups.isEmpty) return _stories.first;
    return _userGroups[_currentGroupIndex].stories[_currentStoryIndex];
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
    _slideAnimationController.dispose();
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

    final currentGroup = _userGroups[_currentGroupIndex];

    // Check if there are more stories in the current user's group
    if (_currentStoryIndex < currentGroup.stories.length - 1) {
      // Move to next story in the same user group
      _currentStoryIndex++;
      _startStoryProgress();
    } else {
      // Move to next user group
      if (_currentGroupIndex < _userGroups.length - 1) {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
        _startStoryProgress();
      } else {
        // No more user groups, exit
        Navigator.of(context).pop();
      }
    }
    setState(() {}); // Refresh UI to show new progress indicators
  }

  void _previousStory() {
    // Mark that user has interacted (viewed stories)
    _hasInteracted = true;

    // Check if there are more stories in the current user's group
    if (_currentStoryIndex > 0) {
      // Move to previous story in the same user group
      _currentStoryIndex--;
      _startStoryProgress();
    } else {
      // Move to previous user group (last story of that group)
      if (_currentGroupIndex > 0) {
        _currentGroupIndex--;
        _currentStoryIndex = _userGroups[_currentGroupIndex].stories.length - 1;
        _startStoryProgress();
      }
      // If already at first group and first story, do nothing
    }
    setState(() {}); // Refresh UI to show new progress indicators
  }

  void _goToNextUserGroup() async {
    // Mark that user has interacted
    _hasInteracted = true;

    // Move to next user group if available
    if (_currentGroupIndex < _userGroups.length - 1 && !_isAnimating) {
      _isAnimating = true;

      // Pause current story progress
      _progressController.stop();

      // Animate slide to right (positive direction)
      _slideAnimation =
          Tween<Offset>(
            begin: const Offset(0.0, 0.0),
            end: const Offset(-1.0, 0.0), // Slide current content left (out)
          ).animate(
            CurvedAnimation(
              parent: _slideAnimationController,
              curve: Curves.easeInOut,
            ),
          );

      await _slideAnimationController.forward();

      // Update group index
      _currentGroupIndex++;
      _currentStoryIndex = 0; // Start from first story of next user

      // Reset animation for next content to slide in from right
      _slideAnimation =
          Tween<Offset>(
            begin: const Offset(1.0, 0.0), // Start from right
            end: const Offset(0.0, 0.0), // Slide to center
          ).animate(
            CurvedAnimation(
              parent: _slideAnimationController,
              curve: Curves.easeInOut,
            ),
          );

      _slideAnimationController.reset();
      setState(() {}); // Update UI with new content

      await _slideAnimationController.forward();

      _isAnimating = false;
      _startStoryProgress(); // Resume story progress
    }
  }

  void _goToPreviousUserGroup() async {
    // Mark that user has interacted
    _hasInteracted = true;

    // Move to previous user group if available
    if (_currentGroupIndex > 0 && !_isAnimating) {
      _isAnimating = true;

      // Pause current story progress
      _progressController.stop();

      // Animate slide to left (negative direction)
      _slideAnimation =
          Tween<Offset>(
            begin: const Offset(0.0, 0.0),
            end: const Offset(1.0, 0.0), // Slide current content right (out)
          ).animate(
            CurvedAnimation(
              parent: _slideAnimationController,
              curve: Curves.easeInOut,
            ),
          );

      await _slideAnimationController.forward();

      // Update group index
      _currentGroupIndex--;
      _currentStoryIndex = 0; // Start from first story of previous user

      // Reset animation for next content to slide in from left
      _slideAnimation =
          Tween<Offset>(
            begin: const Offset(-1.0, 0.0), // Start from left
            end: const Offset(0.0, 0.0), // Slide to center
          ).animate(
            CurvedAnimation(
              parent: _slideAnimationController,
              curve: Curves.easeInOut,
            ),
          );

      _slideAnimationController.reset();
      setState(() {}); // Update UI with new content

      await _slideAnimationController.forward();

      _isAnimating = false;
      _startStoryProgress(); // Resume story progress
    }
  }

  Future<void> _reactToStory(String reactionType) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final currentStory = _currentStory;

    final result = await _postService.reactToStory(
      storyId: currentStory.id,
      reactionType: reactionType,
    );

    result.when(
      success: (data) {
        // Update story with new reaction data, preserving user info
        final reactionData = data['result'];

        // Create new reaction object
        final newReaction = StoryReaction(reactionType: reactionType);

        // Use copyWith to preserve existing user info
        final updatedStory = currentStory.copyWith(
          reactionCount:
              reactionData['reactionCount'] ?? currentStory.reactionCount,
          myReaction: newReaction,
        );

        debugPrint('Updated Story: ${updatedStory.toJson()}');

        // Update the story in both the grouped structure and flat list
        _userGroups[_currentGroupIndex].stories[_currentStoryIndex] =
            updatedStory;

        // Also update the flat list to maintain consistency
        final globalIndex = _getGlobalIndexFromGroupIndices(
          _currentGroupIndex,
          _currentStoryIndex,
        );
        if (globalIndex != -1) {
          _stories[globalIndex] = updatedStory;
        }

        setState(() {});

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

  // Helper method to convert group indices to global index
  int _getGlobalIndexFromGroupIndices(int groupIndex, int storyIndex) {
    int globalIndex = 0;

    for (int i = 0; i < groupIndex; i++) {
      globalIndex += _userGroups[i].stories.length;
    }
    globalIndex += storyIndex;

    return globalIndex < _stories.length ? globalIndex : -1;
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

    final currentStory = _currentStory;

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
        // Remove story from both grouped structure and flat list
        final currentGroup = _userGroups[_currentGroupIndex];
        currentGroup.stories.removeAt(_currentStoryIndex);

        // Remove from flat list
        final globalIndex = _getGlobalIndexFromGroupIndices(
          _currentGroupIndex,
          _currentStoryIndex,
        );
        if (globalIndex != -1) {
          _stories.removeAt(globalIndex);
        }

        // Mark that user has interacted (deleted story)
        _hasInteracted = true;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Check if current group is now empty
        if (currentGroup.stories.isEmpty) {
          _userGroups.removeAt(_currentGroupIndex);

          // If no more groups, exit
          if (_userGroups.isEmpty) {
            Navigator.of(context).pop();
            return;
          }

          // Adjust current group index if needed
          if (_currentGroupIndex >= _userGroups.length) {
            _currentGroupIndex = _userGroups.length - 1;
          }
          _currentStoryIndex = 0;
        } else {
          // Adjust story index if needed
          if (_currentStoryIndex >= currentGroup.stories.length) {
            _currentStoryIndex = currentGroup.stories.length - 1;
          }
        }

        setState(() {});
        _startStoryProgress();
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
    if (_currentUserId == null || _userGroups.isEmpty) return false;
    final currentStory = _currentStory;
    return currentStory.ownerId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    if (_userGroups.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentGroup = _userGroups[_currentGroupIndex];
    final currentStory = _currentStory;

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
        onHorizontalDragEnd: (details) {
          // Handle horizontal swipe to navigate between user groups
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              // Swipe right - go to previous user group
              _goToPreviousUserGroup();
            } else if (details.primaryVelocity! < 0) {
              // Swipe left - go to next user group
              _goToNextUserGroup();
            }
          }
        },
        child: Stack(
          children: [
            // Story Content with Slide Animation - Show current story
            SlideTransition(
              position: _slideAnimation,
              child: _buildStoryContent(currentStory),
            ),

            // Progress Indicators - Show only current user's stories (Facebook-style)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  // User group indicator (optional - shows current user out of total users)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentGroupIndex + 1} / ${_userGroups.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bars for current user's stories only
                  Row(
                    children: List.generate(currentGroup.stories.length, (
                      index,
                    ) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: index == _currentStoryIndex
                                  ? _progressController.value
                                  : index < _currentStoryIndex
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
                ],
              ),
            ),

            // Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top,
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
    final currentStory = _currentStory;
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
