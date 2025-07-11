import 'dart:io';

import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/auth/auth_bloc_adapter.dart';
import 'package:dlstarlive/core/network/api_service.dart';
import 'package:dlstarlive/features/newsfeed/data/datasources/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

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
                  filled: false,
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
                          icon: Icons.photo_outlined,
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
