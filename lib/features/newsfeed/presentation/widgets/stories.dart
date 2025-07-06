import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dlstarlive/features/newsfeed/presentation/widgets/profile_avatar.dart';
import '../pages/create_story_screen.dart';
import '../pages/story_viewer_page.dart';

import '../../../chat/data/models/user_model.dart';
import '../../data/models/story_response_model.dart';
import '../../data/models/stories_api_response_model.dart' as api;

class Stories extends StatelessWidget {
  final User currentUser;
  final List<api.UserStoryGroup> storyGroups;

  const Stories({
    super.key,
    required this.currentUser,
    required this.storyGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: 1 + storyGroups.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: StoryCard(
                isAddStory: true,
                currentUser: currentUser,
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
          final api.UserStoryGroup storyGroup = storyGroups[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: StoryCard(
              storyGroup: storyGroup,
              currentUser: currentUser,
              onTap: () {
                // Convert UserStoryGroup stories to StoryModel for viewer
                List<StoryModel> storyModels = storyGroup.stories.map((
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
                      avatar: storyGroup.avatar != null
                          ? StoryAvatar(
                              name: storyGroup.name,
                              url: storyGroup.avatar!,
                            )
                          : null,
                    ),
                    myReaction: null, // Will be set based on user's reaction
                  );
                }).toList();

                // Navigate to story viewer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryViewerPage(
                      stories: storyModels,
                      initialIndex: 0,
                      currentUserId: currentUser.id.toString(),
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

class StoryCard extends StatelessWidget {
  final bool isAddStory;
  final User? currentUser;
  final api.UserStoryGroup? storyGroup;
  final VoidCallback? onTap;

  const StoryCard({
    super.key,
    this.isAddStory = false,
    this.currentUser,
    this.storyGroup,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: CachedNetworkImage(
              imageUrl: isAddStory
                  ? currentUser!.avatar
                  : storyGroup?.latestStory?.mediaUrl ?? "",
              height: double.infinity,
              width: 110.0,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            height: double.infinity,
            width: 110.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black26],
              ),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4.0,
                ),
              ],
            ),
          ),
          Positioned(
            top: 8.0,
            left: 8.0,
            child: isAddStory
                ? Container(
                    height: 40.0,
                    width: 40.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add),
                      iconSize: 30.0,
                      color: Colors.blue,
                      onPressed: () => print('Add to Story'),
                    ),
                  )
                : ProfileAvatar(
                    imageUrl: storyGroup?.avatar ?? "",
                    hasBorder: !storyGroup!.allStoriesViewed,
                  ),
          ),
          Positioned(
            bottom: 8.0,
            left: 8.0,
            right: 8.0,
            child: Text(
              isAddStory ? 'Add to Story' : storyGroup?.name ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
