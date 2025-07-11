import 'package:dlstarlive/core/network_temp/api_service.dart';
import 'package:dlstarlive/core/auth/auth_bloc_adapter.dart';
import 'package:dlstarlive/features/newsfeed/data/models/mock_models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/network_temp/post_service.dart';
import '../pages/create_story_screen.dart';
import '../pages/story_viewer_page.dart';

import '../../data/models/story_response_model.dart';
import '../../data/models/stories_api_response_model.dart' as api;

class ApiStories extends StatefulWidget {
  final User currentUser;
  final VoidCallback? onStoryUploaded;

  const ApiStories({
    super.key,
    required this.currentUser,
    this.onStoryUploaded,
  });

  @override
  State<ApiStories> createState() => _ApiStoriesState();
}

class _ApiStoriesState extends State<ApiStories> {
  late PostService _postService;
  List<api.UserStoryGroup> _storyGroups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState(); // Initialize services
    final apiService = ApiService.instance;
    final authService = AuthBlocAdapter(context);
    _postService = PostService(apiService, authService);
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _postService.getAllStories(limit: 20);

    result.when(
      success: (data) {
        final storiesApiResponse = api.StoriesApiResponse.fromJson(data);
        setState(() {
          _storyGroups = storiesApiResponse.result.data;
          _isLoading = false;
        });
      },
      failure: (error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
    );
  }

  // Public method to refresh stories from external widgets
  Future<void> refreshStories() async {
    // Briefly show loading state during refresh
    setState(() {
      _isLoading = true;
    });

    await _loadStories();

    // Show a subtle indication that stories were refreshed
    if (mounted) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: const Text('Stories updated'),
      //     duration: const Duration(seconds: 1),
      //     backgroundColor: Colors.green.withOpacity(0.8),
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //     margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      //   ),
      // );
      debugPrint('Stories refreshed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0,
      color: Colors.white,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load stories',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadStories,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 8.0,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: 1 + _storyGroups.length,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ApiStoryCard(
                      isAddStory: true,
                      currentUser: widget.currentUser,
                      onTap: () async {
                        // Navigate to create story screen and refresh on upload
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateStoryScreen(
                              onStoryUploaded: widget.onStoryUploaded,
                            ),
                          ),
                        );
                        // Optionally refresh stories if needed
                        if (result == true) {
                          await refreshStories();
                        }
                      },
                    ),
                  );
                }
                final storyGroup = _storyGroups[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ApiStoryCard(
                    storyGroup: storyGroup,
                    currentUser: widget.currentUser,
                    onTap: () {
                      // Convert ALL story groups to a flat list of StoryModel
                      List<StoryModel> allStories = [];
                      int targetIndex = 0;

                      // Process all story groups
                      for (
                        int groupIndex = 0;
                        groupIndex < _storyGroups.length;
                        groupIndex++
                      ) {
                        final group = _storyGroups[groupIndex];

                        // Convert stories from this group
                        List<StoryModel> groupStories = group.stories.map((
                          storyItem,
                        ) {
                          return StoryModel(
                            id: storyItem.id,
                            ownerId: storyItem.ownerId,
                            mediaUrl: storyItem.mediaUrl,
                            reactionCount: storyItem.reactionCount,
                            createdAt: storyItem.createdAt,
                            userInfo: StoryUserInfo(
                              id: storyItem.userInfo.id,
                              name: storyItem.userInfo.name,
                              avatar: storyItem.userInfo.avatar ?? '',
                            ),
                            myReaction: storyItem.myReaction != null
                                ? StoryReaction(
                                    reactionType:
                                        storyItem.myReaction!.reactionType,
                                  )
                                : null,
                          );
                        }).toList();

                        // If this is the tapped group, remember the starting index
                        if (groupIndex == index - 1) {
                          targetIndex = allStories.length;
                        }

                        allStories.addAll(groupStories);
                      }

                      // Navigate to story viewer with all stories, starting at the tapped group
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryViewerPage(
                            stories: allStories,
                            initialIndex: targetIndex,
                            currentUserId: widget.currentUser.id.toString(),
                            onStoriesUpdated: () async {
                              // Refresh stories when user comes back from story viewer
                              await refreshStories();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class ApiStoryCard extends StatelessWidget {
  final bool isAddStory;
  final User? currentUser;
  final StoryModel? story;
  final api.UserStoryGroup? storyGroup;
  final VoidCallback? onTap;

  const ApiStoryCard({
    super.key,
    this.isAddStory = false,
    this.currentUser,
    this.story,
    this.storyGroup,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          SizedBox(
            width: 110.0,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 110.0,
                      height: 150.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isAddStory
                              ? Colors.grey[400]!
                              : _hasUnseenStories()
                              ? Colors.blue
                              : Colors.grey[400]!,
                          width: 3.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9.0),
                        child: isAddStory
                            ? _buildAddStoryContent()
                            : _buildStoryContent(),
                      ),
                    ),
                    if (isAddStory)
                      Positioned(
                        bottom: 8.0,
                        right: 8.0,
                        child: Container(
                          height: 25.0,
                          width: 25.0,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18.0,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  isAddStory ? 'Your Story' : _getUserName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (!isAddStory && _hasMyReaction())
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _getMyReactionEmoji(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddStoryContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        currentUser?.avatar != null &&
                currentUser!.avatar.isNotEmpty &&
                currentUser!.avatar.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: currentUser!.avatar,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 50),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 50),
              ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryContent() {
    final mediaUrl = story?.mediaUrl ?? storyGroup?.latestStory?.mediaUrl ?? '';
    final avatarUrl = story?.userInfo?.avatar ?? storyGroup?.avatar;
    final userName = story?.userInfo?.name ?? storyGroup?.name ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 50),
          ),
        ),
        // User avatar overlay
        Positioned(
          top: 8.0,
          left: 8.0,
          child: Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 14.0,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              backgroundColor: Colors.grey[600],
              child: avatarUrl == null
                  ? Text(
                      userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        // Reaction count
        if (story?.reactionCount != null && story!.reactionCount > 0)
          Positioned(
            bottom: 8.0,
            left: 8.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '${story!.reactionCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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

  bool _hasMyReaction() {
    if (story?.myReaction != null) {
      return true;
    } else if (storyGroup != null) {
      // Check if the latest story has a reaction
      return storyGroup!.latestStory?.myReaction != null;
    }
    return false;
  }

  String _getMyReactionEmoji() {
    String? reactionType;
    if (story?.myReaction != null) {
      reactionType = story!.myReaction!.reactionType;
    } else if (storyGroup?.latestStory?.myReaction != null) {
      reactionType = storyGroup!.latestStory!.myReaction!.reactionType;
    }

    return _getReactionEmoji(reactionType ?? 'like');
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
        return '🤗';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      default:
        return '👍';
    }
  }

  bool _getViewedStatus() {
    if (story != null) {
      return story!.isViewed;
    } else if (storyGroup != null) {
      return storyGroup!.allStoriesViewed;
    }
    return false;
  }

  bool _hasUnseenStories() {
    if (storyGroup != null) {
      // Check if there are stories without reactions (indicating unseen)
      return storyGroup!.stories.any((story) => story.myReaction == null);
    }
    return !_getViewedStatus();
  }

  String _getUserName() {
    if (story != null) {
      return story?.userInfo?.name ?? 'Unknown';
    } else if (storyGroup != null) {
      return storyGroup?.name ?? 'Unknown';
    }
    return 'Unknown';
  }
}
