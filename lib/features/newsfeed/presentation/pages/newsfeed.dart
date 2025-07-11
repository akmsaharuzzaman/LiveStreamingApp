import 'dart:io';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/models/user_model.dart';
import 'package:dlstarlive/core/network_temp/api_service.dart';
import 'package:dlstarlive/core/network_temp/post_service.dart';
import 'package:dlstarlive/features/newsfeed/data/models/mock_models/user_model.dart';
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

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _postController = TextEditingController();
  bool _isPostEnabled = false;
  bool _isPosting = false;
  File? _selectedImage;
  late PostService _postService;

  @override
  void initState() {
    super.initState(); // Initialize post creation service
    _postService = PostService(ApiService.instance, AuthBlocAdapter(context));
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _onPostChanged(String text) {
    setState(() {
      _isPostEnabled = text.trim().isNotEmpty || _selectedImage != null;
    });
  }

  void _onImageSelected() {
    setState(() {
      _isPostEnabled =
          _postController.text.trim().isNotEmpty || _selectedImage != null;
    });
  }

  Future<void> _createPost() async {
    if (!_isPostEnabled || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final result = await _postService.createPost(
        postCaption: _postController.text.trim().isNotEmpty
            ? _postController.text.trim()
            : null,
        mediaFile: _selectedImage,
      );

      if (result.isSuccess) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Return success result to refresh the feed
          Navigator.pop(context, true);
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorOrNull ?? 'Failed to create post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _onImageSelected();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    _onImageSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Create Post'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: _isPosting
                ? Container(
                    width: 20.w,
                    height: 20.h,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _isPostEnabled ? _createPost : null,
                    style: TextButton.styleFrom(
                      backgroundColor: _isPostEnabled
                          ? Colors.blue
                          : Colors.grey[300],
                      foregroundColor: _isPostEnabled
                          ? Colors.white
                          : Colors.grey[600],
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                    child: Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture and Name
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final userName = authState is AuthAuthenticated
                      ? authState.user.name
                      : 'Your Name';
                  final userAvatar = authState is AuthAuthenticated
                      ? authState.user.avatar
                      : null;

                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        radius: 20.r,
                        backgroundImage: userAvatar != null
                            ? NetworkImage(userAvatar)
                            : null,
                        child: userAvatar == null
                            ? Icon(
                                Icons.person,
                                size: 24.sp,
                                color: Colors.grey[600],
                              )
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.public,
                                size: 12.sp,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Public',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16.h),

              // Text Field
              TextFormField(
                controller: _postController,
                onChanged: _onPostChanged,
                maxLines: null,
                minLines: 3,
                style: TextStyle(fontSize: 16.sp),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              // Image Preview
              if (_selectedImage != null) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: 300.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: EdgeInsets.all(4.sp),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 20.h),

              // Options Row
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add to your post',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        _buildOptionButton(
                          icon: Iconsax.gallery,
                          label: 'Photo',
                          color: Colors.green,
                          onTap: _selectImage,
                        ),
                        SizedBox(width: 16.w),
                        _buildOptionButton(
                          icon: Icons.videocam_outlined,
                          label: 'Video',
                          color: Colors.blue,
                          onTap: () {
                            // TODO: Implement video selection
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Video selection coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Post Guidelines
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Share what\'s on your mind! You can post text, photos, or both.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
