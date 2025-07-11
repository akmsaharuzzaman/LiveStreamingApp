import 'dart:io';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/models/user_model.dart';
import 'package:dlstarlive/core/network/api_service.dart';
import 'package:dlstarlive/features/newsfeed/data/datasources/post_service.dart';
import 'package:dlstarlive/features/newsfeed/data/models/mock_models/user_model.dart';
import 'package:dlstarlive/features/newsfeed/presentation/pages/create_post_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/auth/auth_bloc_adapter.dart';
import '../../injection_container.dart';
import '../bloc/newsfeed_bloc.dart';
import '../widgets/create_post_container.dart';
import '../widgets/api_post_container.dart';
import '../widgets/api_stories.dart';

// Helper function to convert UserEntity to the User model expected by widgets
User userEntityToUser(UserModel userEntity) {
  return User(
    id: userEntity.id.hashCode, // Convert string ID to int
    name: userEntity.name,
    avatar: userEntity.avatar ?? '',
  );
}

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({super.key});

  @override
  State<NewsfeedPage> createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  final TrackingScrollController scrollController = TrackingScrollController();
  late NewsfeedBloc _newsfeedBloc;
  final GlobalKey _apiStoriesKey = GlobalKey();

  // Toggle between mock stories and API stories
  bool useApiStories =
      true; // Set to true to use API stories, false for mock stories

  @override
  void initState() {
    super.initState();
    _newsfeedBloc = NewsfeedDependencyContainer.createNewsfeedBloc();
    // Load initial posts
    _newsfeedBloc.add(const LoadPostsEvent());
  }

  @override
  void dispose() {
    scrollController.dispose();
    _newsfeedBloc.close();
    super.dispose();
  }

  Future<void> _refreshFeed() async {
    // Refresh posts
    _newsfeedBloc.add(RefreshPostsEvent());

    // Refresh stories if using API stories
    if (useApiStories && _apiStoriesKey.currentState != null) {
      final apiStoriesState = _apiStoriesKey.currentState as dynamic;
      await apiStoriesState.refreshStories();
    }

    // Wait for the state to change
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NewsfeedBloc>(
      create: (context) => _newsfeedBloc,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: RefreshIndicator(
            // Position indicator at 30% of screen height instead of bottom
            displacement: MediaQuery.of(context).size.height * 0.3,
            onRefresh: _refreshFeed,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  title: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/dl_star_logo.svg',
                        height: 16,
                        width: 40,
                      ),
                    ],
                  ),
                  centerTitle: false,
                  floating: true,
                  actions: [
                    GestureDetector(
                      onTap: () {
                        // Use try-catch for better error handling
                        try {
                          context.push("/reels");
                        } catch (e) {
                          debugPrint('Error navigating to reels: $e');
                          // Fallback navigation
                          Navigator.of(context).pushNamed('/reels');
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Iconsax.instagram, size: 16.sp),
                          SizedBox(width: 5.sp),
                          Text(
                            'Reels',
                            style: GoogleFonts.aBeeZee(
                              fontSize: 13.sp,
                              color: const Color(0xff2c3968),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20.sp),
                    Icon(Icons.search, size: 22.sp),
                    SizedBox(width: 15.sp),
                    GestureDetector(
                      onTap: () {
                        context.push("/live-chat");
                      },
                      child: Image.asset(
                        'assets/images/general/messenger.png',
                        height: 28.sp,
                        width: 28.sp,
                      ),
                    ),
                    SizedBox(width: 15.sp),
                  ],
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                ),
                SliverToBoxAdapter(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      // Use auth user data instead of mock currentUser
                      if (authState is AuthAuthenticated) {
                        final user = userEntityToUser(authState.user);
                        return CreatePostContainer(
                          currentUser: user,
                          onCreatePost: () async {
                            // Navigate to create post page
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePostPage(),
                              ),
                            );

                            // If post was created successfully, refresh the feed
                            if (result == true) {
                              _newsfeedBloc.add(RefreshPostsEvent());
                            }
                          },
                        );
                      }
                      // Fallback to mock user if not authenticated
                      return BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthAuthenticated) {
                            return CreatePostContainer(
                              currentUser: userEntityToUser(state.user),
                              onCreatePost: () async {
                                // Navigate to create post page
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreatePostPage(),
                                  ),
                                );

                                // If post was created successfully, refresh the feed
                                if (result == true) {
                                  _newsfeedBloc.add(RefreshPostsEvent());
                                }
                              },
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  sliver: SliverToBoxAdapter(
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        if (authState is AuthAuthenticated) {
                          final user = userEntityToUser(authState.user);
                          return useApiStories
                              ? ApiStories(
                                  key: _apiStoriesKey,
                                  currentUser: user,
                                  onStoryUploaded: _refreshFeed,
                                )
                              : SizedBox();
                        } else {
                          return Text(
                            'Please log in to see stories',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          );
                        }
                      },
                    ),
                  ),
                ),
                // Use BlocBuilder to show posts from API
                BlocBuilder<NewsfeedBloc, NewsfeedState>(
                  builder: (context, state) {
                    if (state is NewsfeedLoading) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    } else if (state is NewsfeedLoaded) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= state.posts.length) {
                              // Show loading indicator at the end
                              if (!state.hasReachedMax) {
                                // Trigger load more posts
                                _newsfeedBloc.add(LoadMorePostsEvent());
                                return const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return null;
                            }
                            final post = state.posts[index];
                            return ApiPostContainer(
                              post: post,
                              onPostDeleted: () {
                                // Refresh the feed when a post is deleted
                                _newsfeedBloc.add(RefreshPostsEvent());
                              },
                              onPostUpdated: () {
                                // Only refresh for major updates (not likes/comments)
                                // Most updates are now handled optimistically
                                debugPrint(
                                  'Post updated callback - considering refresh',
                                );
                                // We can add logic here to determine if a full refresh is needed
                                // For now, we'll skip the refresh since likes and comments are optimistic
                              },
                            );
                          },
                          childCount: state.hasReachedMax
                              ? state.posts.length
                              : state.posts.length + 1,
                        ),
                      );
                    } else if (state is NewsfeedError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text(
                                  'Error loading posts: ${state.message}',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  onPressed: () {
                                    _newsfeedBloc.add(RefreshPostsEvent());
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Show no posts message when API is not working or no posts available
                    return SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(40.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.post_add_outlined,
                              size: 64.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No posts yet',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Be the first to share something!',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SliverPadding(padding: EdgeInsets.only(top: 20.sp)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
