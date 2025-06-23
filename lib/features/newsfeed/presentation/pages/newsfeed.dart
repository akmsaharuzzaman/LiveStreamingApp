import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../components/utilities/chat_theme.dart';
import '../../data/models/mock_models/data.dart';
import '../../data/models/mock_models/post_model.dart';
import '../../injection_container.dart';
import '../bloc/newsfeed_bloc.dart';
import '../widgets/create_post_container.dart';
import '../widgets/post_container.dart';
import '../widgets/stories.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final TrackingScrollController scrollController = TrackingScrollController();
  late NewsfeedBloc _newsfeedBloc;

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NewsfeedBloc>(
      create: (context) => _newsfeedBloc,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              _newsfeedBloc.add(RefreshPostsEvent());
              // Wait for the state to change
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  title: Row(
                    children: [
                      Image.asset(
                        'assets/images/new_images/ic_logo_white.png',
                        height: 40.sp,
                        width: 40.sp,
                      ),
                      SizedBox(width: 5.sp),
                      Text('DLStar Live', style: MyTheme.kAppTitle),
                    ],
                  ),
                  centerTitle: false,
                  floating: true,
                  actions: [
                    GestureDetector(
                      onTap: () {
                        context.push("/reels");
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
                        'assets/images/new_images/messenger.png',
                        height: 28.sp,
                        width: 28.sp,
                      ),
                    ),
                    SizedBox(width: 15.sp),
                  ],
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                ),
                SliverToBoxAdapter(
                  child: CreatePostContainer(currentUser: currentUser),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  sliver: SliverToBoxAdapter(
                    child: Stories(currentUser: currentUser, stories: stories),
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
                            return _buildApiPostContainer(post);
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

                    // Fallback to mock data if API is not working
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final Post post = posts[index];
                        return PostContainer(post: post);
                      }, childCount: posts.length),
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

  Widget _buildApiPostContainer(post) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5.sp, horizontal: 0.0),
      elevation: 1.sp,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.sp)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.sp),
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildApiPostHeader(post),
                  SizedBox(height: 4.h),
                  // Handle null postCaption with better spacing
                  if (post.postCaption != null &&
                      post.postCaption!.trim().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        post.postCaption!.trim(),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                ],
              ),
            ),
            // Handle media with better error handling - only show if mediaUrl exists and is not empty
            if (post.mediaUrl != null && post.mediaUrl!.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: _buildPostImage(post.mediaUrl!.trim()),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: _buildApiPostStats(post),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiPostHeader(dynamic post) {
    return Row(
      children: [
        // Profile Avatar with null handling
        _buildUserAvatar(post.userInfo?.avatar?.url, post.userInfo?.name),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.userInfo?.name ?? 'Unknown User',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${_formatDate(post.updatedAt ?? post.createdAt)} • ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.public, color: Colors.grey[600], size: 12.sp),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_horiz, size: 20.sp),
          onPressed: () => _showPostOptions(post),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(String? avatarUrl, String? userName) {
    return CircleAvatar(
      radius: 20.r,
      backgroundColor: MyTheme.kPrimaryColor,
      child: CircleAvatar(
        radius: 17.r,
        backgroundColor: Colors.grey[200],
        child: ClipOval(child: _buildAvatarContent(avatarUrl, userName)),
      ),
    );
  }

  Widget _buildAvatarContent(String? avatarUrl, String? userName) {
    // Check if avatarUrl is null, empty, or invalid
    if (avatarUrl == null ||
        avatarUrl.trim().isEmpty ||
        !_isValidUrl(avatarUrl.trim())) {
      return Container(
        width: 34.w,
        height: 34.h,
        color: Colors.grey[300],
        child: Icon(Icons.person, size: 20.sp, color: Colors.grey[600]),
      );
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl.trim(),
      width: 34.w,
      height: 34.h,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 34.w,
        height: 34.h,
        color: Colors.grey[200],
        child: Center(
          child: SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 34.w,
        height: 34.h,
        color: Colors.grey[300],
        child: Icon(Icons.person, size: 20.sp, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildPostImage(String imageUrl) {
    // Check if it's a valid URL
    if (!_isValidUrl(imageUrl)) {
      return Container(
        height: 200.h,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey, size: 48.sp),
              SizedBox(height: 8.h),
              Text(
                'Invalid media URL',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 200.h,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
              SizedBox(height: 8.h),
              Text(
                'Loading image...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200.h,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 48.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8.h),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiPostStats(dynamic post) {
    // Safely handle reaction and comment counts
    final int safeReactionCount = (post.reactionCount ?? 0) > 0
        ? (post.reactionCount ?? 0)
        : 0;
    final int safeCommentCount = (post.commentCount ?? 0) > 0
        ? (post.commentCount ?? 0)
        : 0;
    final bool hasReactions = safeReactionCount > 0;
    final bool hasComments = safeCommentCount > 0;

    return Column(
      children: [
        // Only show stats row if there are reactions or comments
        if (hasReactions || hasComments)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                if (hasReactions) ...[
                  Container(
                    padding: EdgeInsets.all(4.sp),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.thumb_up,
                      size: 10.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatCount(safeReactionCount),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                  ),
                ],
                const Spacer(),
                if (hasComments)
                  Text(
                    '$safeCommentCount Comment${safeCommentCount != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                  ),
              ],
            ),
          ),
        // Divider line
        if (hasReactions || hasComments)
          Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),
        // Action buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildApiPostButton(
              icon: Icon(
                MdiIcons.thumbUpOutline,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              label: 'Like',
              onTap: () => _handleReaction(post),
            ),
            _buildApiPostButton(
              icon: Icon(
                MdiIcons.commentOutline,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              label: 'Comment',
              onTap: () => _handleComment(post),
            ),
            _buildApiPostButton(
              icon: Icon(
                MdiIcons.shareOutline,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              label: 'Share',
              onTap: () => _handleShare(post),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApiPostButton({
    required Icon icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  void _showPostOptions(dynamic post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Save Post'),
              onTap: () {
                Navigator.pop(context);
                // Handle save post
                print('Save post: ${post.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                // Handle report post
                print('Report post: ${post.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Hide Post'),
              onTap: () {
                Navigator.pop(context);
                // Handle hide post
                print('Hide post: ${post.id}');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleReaction(dynamic post) {
    // TODO: Implement reaction functionality
    print('React to post: ${post.id}');
  }

  void _handleComment(dynamic post) {
    // TODO: Navigate to comments screen
    print('Comment on post: ${post.id}');
  }

  void _handleShare(dynamic post) {
    // TODO: Implement share functionality
    print('Share post: ${post.id}');
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
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
  File? _selectedImage;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _onPostChanged(String text) {
    setState(() {
      _isPostEnabled = text.isNotEmpty;
    });
  }

  void _createPost() {
    if (_isPostEnabled) {
      Navigator.pop(context, _postController.text);
    }
  }

  void _selectImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _isPostEnabled ? _createPost : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Picture and Name
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 20,
                    child: Image.asset('assets/images/new_images/person.png'),
                  ),
                  SizedBox(width: 10),
                  Text('Wahidur Zaman'),
                ],
              ),
              SizedBox(height: 10),

              // Text Field
              TextFormField(
                controller: _postController,
                onChanged: _onPostChanged,
                maxLines: 5,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'What\'s on your mind?',
                  hintStyle: TextStyle(
                    color: const Color(0xff3E5057),
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.sp).r,
                    borderSide: BorderSide(
                      width: 1.sp,
                      color: Colors.grey.shade200,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.sp),
                    borderSide: BorderSide(
                      width: 1.w,
                      color: Colors.grey.shade200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.sp),
                    borderSide: BorderSide(
                      width: 1.w,
                      color: Colors.grey.shade200,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.sp),
                    borderSide: BorderSide(
                      width: 1.w,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
              ),

              // Image Preview
              if (_selectedImage != null)
                Container(
                  height: 300.sp,
                  width: 450,
                  margin: EdgeInsets.only(top: 10),
                  child: Image.file(_selectedImage!),
                ),
              SizedBox(height: 10),
              // Add Image Button
              GestureDetector(
                onTap: _selectImage,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Iconsax.gallery,
                      size: 22,
                      color: MyTheme.kPrimaryColor,
                    ),
                    SizedBox(width: 5),
                    Text('Photo'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
