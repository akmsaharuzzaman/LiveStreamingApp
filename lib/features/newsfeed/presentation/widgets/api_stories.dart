import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../pages/create_story_screen.dart';
import '../pages/story_viewer_page.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/simple_auth_service.dart';
import '../../../../core/network/api_service.dart';

import '../../../chat/data/models/user_model.dart';
import '../../data/models/story_response_model.dart';

class ApiStories extends StatefulWidget {
  final User currentUser;

  const ApiStories({super.key, required this.currentUser});

  @override
  State<ApiStories> createState() => _ApiStoriesState();
}

class _ApiStoriesState extends State<ApiStories> {
  late PostService _postService;
  List<StoryModel> _stories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize services
    final apiService = ApiService.instance;
    final authService = AuthService();
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
        final storyResponse = StoryResponse.fromJson(data);
        setState(() {
          _stories = storyResponse.result.data;
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
              itemCount: 1 + _stories.length,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ApiStoryCard(
                      isAddStory: true,
                      currentUser: widget.currentUser,
                      onTap: () {
                        // Navigate to create story screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateStoryScreen(),
                          ),
                        );
                      },
                    ),
                  );
                }
                final story = _stories[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ApiStoryCard(
                    story: story,
                    currentUser: widget.currentUser,
                    onTap: () {
                      // Navigate to story viewer with all stories
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryViewerPage(
                            stories: _stories,
                            initialIndex: index - 1,
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
  final VoidCallback? onTap;

  const ApiStoryCard({
    super.key,
    this.isAddStory = false,
    this.currentUser,
    this.story,
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
                              : story?.isViewed == true
                              ? Colors.grey[400]!
                              : Colors.blue,
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
                  isAddStory
                      ? 'Your Story'
                      : story?.userInfo?.name ?? 'Unknown',
                  maxLines: 2,
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
          if (!isAddStory && story?.myReaction != null)
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
                  _getReactionEmoji(story!.myReaction!.reactionType),
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
        currentUser?.avatar != null
            ? currentUser!.avatar.startsWith('http')
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
                  : Image.asset(currentUser!.avatar, fit: BoxFit.cover)
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
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: story?.mediaUrl ?? '',
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
              backgroundImage: story?.userInfo?.avatar?.url != null
                  ? CachedNetworkImageProvider(story!.userInfo!.avatar!.url)
                  : null,
              backgroundColor: Colors.grey[600],
              child: story?.userInfo?.avatar?.url == null
                  ? Text(
                      story?.userInfo?.name.substring(0, 1).toUpperCase() ??
                          '?',
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
}
