import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dlstarlive/features/newsfeed/presentation/widgets/profile_avatar.dart';

import '../../../chat/data/models/user_model.dart';
import '../../data/models/mock_models/story_model.dart';

class Stories extends StatelessWidget {
  final User currentUser;
  final List<Story> stories;

  const Stories({super.key, required this.currentUser, required this.stories});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: 1 + stories.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: StoryCard(
                isAddStory: true,
                currentUser: currentUser,
                onTap: () {
                  // Handle add story tap
                  print('Add Story tapped');
                },
              ),
            );
          }
          final Story story = stories[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: StoryCard(
              story: story,
              currentUser: currentUser,
              onTap: () {
                // Handle story tap
                print('Story tapped: ${story.user.id}');
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
  final Story? story;
  final VoidCallback? onTap;

  const StoryCard({
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: CachedNetworkImage(
              imageUrl: isAddStory
                  ? currentUser!.avatar
                  : story?.imageUrl ?? "",
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
                    imageUrl: story?.user.avatar ?? "",
                    hasBorder: !story!.isViewed,
                  ),
          ),
          Positioned(
            bottom: 8.0,
            left: 8.0,
            right: 8.0,
            child: Text(
              isAddStory ? 'Add to Story' : story?.user.name ?? "",
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
