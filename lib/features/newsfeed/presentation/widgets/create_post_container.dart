import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../chat/data/models/user_model.dart';
import '../pages/newsfeed.dart';
import 'profile_avatar.dart';

class CreatePostContainer extends StatefulWidget {
  final User currentUser;
  final VoidCallback? onCreatePost;

  const CreatePostContainer({
    super.key,
    required this.currentUser,
    this.onCreatePost,
  });

  @override
  State<CreatePostContainer> createState() => _CreatePostContainerState();
}

class _CreatePostContainerState extends State<CreatePostContainer> {
  final TextEditingController _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _createPost() {
    if (widget.onCreatePost != null) {
      widget.onCreatePost!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return CreatePostPage();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: 12.sp,
        left: 12.sp,
        top: 12.sp,
        bottom: 12.sp,
      ),
      child: Column(
        children: [
          Row(
            children: [
              ProfileAvatar(imageUrl: widget.currentUser.avatar),
              SizedBox(width: 8.sp),
              Expanded(
                child: SizedBox(
                  child: TextFormField(
                    readOnly: true,
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    onTap: _createPost,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
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
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
