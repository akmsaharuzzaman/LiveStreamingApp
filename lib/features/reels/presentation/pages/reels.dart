import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:reels_viewer/reels_viewer.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  List<ReelModel> reelsList = [
    ReelModel(
        'https://parsefiles.back4app.com/SM60vnNNpjvoH6PA6ljZAa6IyAYVb1oWVVid8G4A/825ccd06d87e4f707cf54d746a9f017c_lv_7263925596898610433_20230818030011_1738902212119.mp4',
        'Darshan Patil',
        likeCount: 2000,
        isLiked: true,
        musicName: 'In the name of Love',
        reelDescription: "Life is better when you're laughing.",
        profileUrl:
            'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
        commentList: [
          ReelCommentModel(
            comment: 'Nice...',
            userProfilePic:
                'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
            userName: 'Darshan',
            commentTime: DateTime.now(),
          ),
          ReelCommentModel(
            comment: 'Superr...',
            userProfilePic:
                'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
            userName: 'Darshan',
            commentTime: DateTime.now(),
          ),
          ReelCommentModel(
            comment: 'Great...',
            userProfilePic:
                'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
            userName: 'Darshan',
            commentTime: DateTime.now(),
          ),
        ]),
    ReelModel(
      'https://parsefiles.back4app.com/SM60vnNNpjvoH6PA6ljZAa6IyAYVb1oWVVid8G4A/fd1764f362cf3b5530bd48aef7aa05f5_VID-20250209-WA0027_1739109909693.mp4',
      'Rahul',
      musicName: 'In the name of Love',
      reelDescription: "Life is better when you're laughing.",
      profileUrl:
          'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
    ),
  ];
  int currentIndex = 0;
  late PreloadPageController pageController;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Stack(
        children: [
          ReelsViewer(
            reelsList: reelsList,
            appbarTitle: 'Reels',
            onShare: (url) {
              log('Shared reel url ==> $url');
            },
            onLike: (url) {
              log('Liked reel url ==> $url');
            },
            onFollow: () {
              log('======> Clicked on follow <======');
            },
            onComment: (comment) {
              log('Comment on reel ==> $comment');
            },
            onClickMoreBtn: () {
              log('======> Clicked on more option <======');
            },
            onClickBackArrow: () {
              log('======> Clicked on back arrow <======');
            },
            onIndexChanged: (index) {
              log('======> Current Index ======> $index <========');
            },
            showProgressIndicator: true,
            showVerifiedTick: true,
            showAppbar: true,
          ),
          Positioned(
            right: 20.sp,
            top: 40.sp,
            child: GestureDetector(
                onTap: () {
                  context.push('/edit-video');
                },
                child: Icon(CupertinoIcons.camera, color: Colors.white)),
          )
        ],
      );
    } catch (e, stack) {
      return Center(child: Text('Error: $e'));
    }
    /*    return Scaffold(
      body: ReelsViewer(
        reelsList: reelsList,
        appbarTitle: 'Instagram Reels',
        onShare: (url) {
          log('Shared reel url ==> $url');
        },
        onLike: (url) {
          log('Liked reel url ==> $url');
        },
        onFollow: () {
          log('======> Clicked on follow <======');
        },
        onComment: (comment) {
          log('Comment on reel ==> $comment');
        },
        onClickMoreBtn: () {
          log('======> Clicked on more option <======');
        },
        onClickBackArrow: () {
          log('======> Clicked on back arrow <======');
        },
        onIndexChanged: (index) {
          log('======> Current Index ======> $index <========');
        },
        showProgressIndicator: true,
        showVerifiedTick: true,
        showAppbar: true,
      ),
    );*/
  }
}
