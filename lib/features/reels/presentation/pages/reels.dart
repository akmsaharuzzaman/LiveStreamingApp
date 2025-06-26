import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:reels_viewer/reels_viewer.dart';

import '../../../../core/network/api_service.dart';
import '../../data/services/reels_api_service.dart';
import '../../domain/entities/reel_entity.dart';
import '../../injection_container.dart';
import '../bloc/reels_bloc.dart';
import '../bloc/reels_event.dart';
import '../bloc/reels_state.dart';
import '../utils/reel_mapper.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late ReelsBloc _reelsBloc;
  List<ReelModel> reelsList = [];
  int currentIndex = 0;
  late PreloadPageController pageController;

  @override
  void initState() {
    super.initState();
    _reelsBloc = ReelsDependencyContainer.createReelsBloc();

    // Test API connection for debugging
    _testApiConnection();

    // Load initial reels
    _reelsBloc.add(LoadReels());
  }

  Future<void> _testApiConnection() async {
    try {
      final apiService = ApiService.instance;
      final reelsApiService = ReelsApiService(apiService);
      await reelsApiService.testConnection();
    } catch (e) {
      log('Error testing API connection: $e');
    }
  }

  @override
  void dispose() {
    _reelsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReelsBloc>(
      create: (context) => _reelsBloc,
      child: BlocBuilder<ReelsBloc, ReelsState>(
        builder: (context, state) {
          if (state is ReelsLoading) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          } else if (state is ReelsLoaded) {
            // Convert entities to ReelModel for the UI
            reelsList = ReelMapper.entitiesToReelModels(state.reels);

            if (reelsList.isEmpty) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Text(
                    'No reels available',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              );
            }

            return _buildReelsViewer();
          } else if (state is ReelsError) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _reelsBloc.add(LoadReels());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initial state - show loading
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        },
      ),
    );
  }

  Widget _buildReelsViewer() {
    try {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          log('======> System back button pressed, didPop: $didPop <======');
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              ReelsViewer(
                reelsList: reelsList,
                appbarTitle: 'Reels',
                onShare: (url) {
                  log('Shared reel url ==> $url');
                  // Find the reel by URL and get its ID
                  final reelEntity = _findReelEntityByUrl(url);
                  if (reelEntity != null) {
                    _reelsBloc.add(ShareReel(reelEntity.id));
                  }
                },
                onLike: (url) {
                  log('Liked reel url ==> $url');
                  // Find the reel by URL and get its ID
                  final reelEntity = _findReelEntityByUrl(url);
                  if (reelEntity != null) {
                    _reelsBloc.add(LikeReel(reelEntity.id));
                  }
                },
                onFollow: () {
                  log('======> Clicked on follow <======');
                },
                onComment: (comment) {
                  log('Comment on reel ==> $comment');
                  // Find current reel and add comment
                  if (currentIndex < reelsList.length) {
                    final reelEntity = _getCurrentReelEntity();
                    if (reelEntity != null) {
                      _reelsBloc.add(AddComment(reelEntity.id, comment));
                    }
                  }
                },
                onClickMoreBtn: () {
                  log('======> Clicked on more option <======');
                },
                onClickBackArrow: () {
                  log('======> Clicked on back arrow <======');
                  // Handle back navigation
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go('/'); // Fallback to home if can't pop
                  }
                },
                onIndexChanged: (index) {
                  log('======> Current Index ======> $index <========');
                  setState(() {
                    currentIndex = index;
                  });

                  // Load more reels when approaching the end
                  final state = _reelsBloc.state;
                  if (state is ReelsLoaded &&
                      index >= reelsList.length - 2 &&
                      !state.hasReachedMax) {
                    _reelsBloc.add(LoadMoreReels());
                  }
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
                  child: const Icon(CupertinoIcons.camera, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Center(child: Text('Error: $e'));
    }
  }

  // Helper method to find reel entity by video URL
  ReelEntity? _findReelEntityByUrl(String url) {
    final state = _reelsBloc.state;
    if (state is ReelsLoaded) {
      try {
        return state.reels.firstWhere((reel) => reel.videoUrl == url);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper method to get current reel entity
  ReelEntity? _getCurrentReelEntity() {
    final state = _reelsBloc.state;
    if (state is ReelsLoaded && currentIndex < state.reels.length) {
      return state.reels[currentIndex];
    }
    return null;
  }
}
