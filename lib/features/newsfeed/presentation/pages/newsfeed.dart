import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../components/utilities/chat_theme.dart';
import '../../data/models/mock_models/data.dart';
import '../../data/models/mock_models/post_model.dart';
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

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          body: CustomScrollView(
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
                Text(
                  'StreamBird',
                  style: MyTheme.kAppTitle,
                ),
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
                    )
                  ],
                ),
              ),
              SizedBox(width: 20.sp),
              Icon(
                Icons.search,
                size: 22.sp,
              ),
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
              child: Stories(
                currentUser: currentUser,
                stories: stories,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final Post post = posts[index];
                return PostContainer(post: post);
              },
              childCount: posts.length,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 20.sp),
          )
        ],
      )),
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
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'What\'s on your mind?',
                  hintStyle: TextStyle(
                      color: const Color(0xff3E5057),
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.sp).r,
                    borderSide:
                        BorderSide(width: 1.sp, color: Colors.grey.shade200),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.sp),
                    borderSide:
                        BorderSide(width: 1.w, color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.sp),
                    borderSide:
                        BorderSide(width: 1.w, color: Colors.grey.shade200),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.sp),
                    borderSide:
                        BorderSide(width: 1.w, color: Colors.grey.shade200),
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
