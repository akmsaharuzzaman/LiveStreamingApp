import 'dart:developer';

import 'package:dlstarlive/core/network/api_service.dart';
import 'package:dlstarlive/features/reels/custom_package/src/models/reel_model.dart';
import 'package:dlstarlive/features/reels/custom_package/src/reels_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:preload_page_view/preload_page_view.dart';
import '../../data/services/reels_api_service.dart';
import '../../domain/entities/reel_entity.dart';
import '../../injection_container.dart';
import '../bloc/reels_bloc.dart';
import '../bloc/reels_event.dart';
import '../bloc/reels_state.dart';
import '../utils/reel_mapper.dart';
import 'reel_comments_page.dart';

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
              return Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.push('/edit-video');
                        },
                        child: const Text('Upload your first reels'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No reels uploaded yet',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
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
                    _shareReel(reelEntity.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📤 Shared!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // For now, just show success message since share might not need exact ID
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📤 Shared!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                onLike: (url) {
                  log('Liked reel url ==> $url');

                  // Find the reel by URL and get its ID
                  final reelEntity = _findReelEntityByUrl(url);
                  if (reelEntity != null) {
                    // Use the direct repository call for reactions
                    _reactToReel(reelEntity.id, 'like');

                    // Show success feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❤️ Liked!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    // Fallback: try to get reel info from current item in reelsList
                    if (currentIndex >= 0 && currentIndex < reelsList.length) {
                      final currentReel = reelsList[currentIndex];
                      final reelId =
                          _extractReelIdFromUrl(currentReel.url) ??
                          DateTime.now().millisecondsSinceEpoch.toString();
                      log(
                        'Using fallback reel ID for like: $reelId for URL: ${currentReel.url}',
                      );
                      _reactToReel(reelId, 'like');

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❤️ Liked!'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onFollow: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('This feature is not implemented yet.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  log('======> Clicked on follow <======');
                },
                onComment: (comment) {
                  log('Comment on reel ==> $comment');

                  // Find current reel and open comments page
                  final reelEntity = _getCurrentReelEntity();
                  if (reelEntity != null) {
                    if (comment.isNotEmpty) {
                      // If there's actual comment text, add it
                      _reelsBloc.add(AddComment(reelEntity.id, comment));
                    } else {
                      // If just clicking comment icon, open comments page
                      _openCommentsPage(reelEntity.id);
                    }
                  } else {
                    // Fallback: try to get reel info from current item in reelsList
                    if (currentIndex >= 0 && currentIndex < reelsList.length) {
                      final currentReel = reelsList[currentIndex];
                      // Extract reel ID from URL or use a default approach
                      final reelId =
                          _extractReelIdFromUrl(currentReel.url) ??
                          DateTime.now().millisecondsSinceEpoch.toString();
                      log(
                        'Using fallback reel ID: $reelId for URL: ${currentReel.url}',
                      );
                      _openCommentsPage(reelId);
                    } else {
                      log(
                        'Cannot open comments: currentIndex=$currentIndex, reelsList.length=${reelsList.length}',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to open comments at this time'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                onClickMoreBtn: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('This feature is not implemented yet.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
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

  // Helper method to extract reel ID from URL
  String? _extractReelIdFromUrl(String url) {
    try {
      // If the URL contains a reel identifier, extract it
      // This is a basic implementation - adjust based on your URL structure
      if (url.contains('/')) {
        final parts = url.split('/');
        return parts.last.split('.').first; // Get filename without extension
      }
      return url; // Return the URL itself as ID if no path separators
    } catch (e) {
      log('Error extracting reel ID from URL: $e');
      return null;
    }
  }

  // Helper method to react to a reel
  Future<void> _reactToReel(String reelId, String reactionType) async {
    try {
      final repository = ReelsDependencyContainer.createRepository();
      final success = await repository.reactToReel(reelId, reactionType);

      if (success) {
        log('Successfully reacted to reel: $reelId with $reactionType');
        // Optionally refresh the current reel to show updated reaction count
      } else {
        log('Failed to react to reel: $reelId');
      }
    } catch (e) {
      log('Error reacting to reel: $e');
    }
  }

  // Helper method to share a reel
  Future<void> _shareReel(String reelId) async {
    try {
      final repository = ReelsDependencyContainer.createRepository();
      final success = await repository.shareReel(reelId);

      if (success) {
        log('Successfully shared reel: $reelId');
      } else {
        log('Failed to share reel: $reelId');
      }
    } catch (e) {
      log('Error sharing reel: $e');
    }
  }

  // Helper method to open comments page for a reel
  void _openCommentsPage(String reelId) {
    log('Opening comments page for reel ID: $reelId');
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReelCommentsPage(reelId: reelId, reelTitle: 'Reel Comments'),
        ),
      );
    } catch (e) {
      log('Error opening comments page: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening comments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
