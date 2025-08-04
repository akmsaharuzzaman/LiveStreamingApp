import 'package:dlstarlive/features/live/presentation/component/local_game_config.dart';
import 'package:dlstarlive/features/live/presentation/component/local_game_manager.dart';
import 'package:dlstarlive/features/live/presentation/pages/local_game_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showGameBottomSheet(
  BuildContext context, {
  String? userId,
  bool isHost = false,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return GameBottomSheet(userId: userId, isHost: isHost);
    },
  );
}

class GameBottomSheet extends StatefulWidget {
  final String? userId;
  final bool isHost;

  const GameBottomSheet({super.key, this.userId, required this.isHost});

  @override
  State<GameBottomSheet> createState() => _GameBottomSheetState();
}

class _GameBottomSheetState extends State<GameBottomSheet> {
  List<LocalGameConfig> _localGames = [];
  bool _isLoading = true;
  bool _isStartingGame = false;
  String? _currentGameTitle;
  LocalGameConfig? _activeGame;
  double gameHeight = 0.7;
  late double modalHight;

  @override
  void initState() {
    super.initState();
    modalHight = widget.isHost ? 0.7 : 0.25;
    _loadLocalGames();
  }

  Future<void> _loadLocalGames() async {
    try {
      final games = await LocalGameManager.instance.getAvailableGames();
      setState(() {
        _localGames = games;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load local games: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Original bottom sheet content
        if (_activeGame == null)
          Container(
            height: (_activeGame != null)
                ? MediaQuery.of(context).size.height * gameHeight
                : widget.isHost
                ? MediaQuery.of(context).size.height * .55
                : MediaQuery.of(context).size.height * modalHight,
            decoration: BoxDecoration(
              // color: const Color(0xFF1A1A2E),
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE5FE), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                // Stream Duration and Game Status
                Container(
                  margin: EdgeInsets.symmetric(vertical: 16.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.all(Radius.circular(10.r)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Stream Duration: 000:00:00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),

                // Game Options Section
                SizedBox(
                  height: 90.h,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 2.w, right: 20.w),
                          children: [
                            // Dynamic Local Games
                            ..._localGames.map(
                              (game) => Padding(
                                padding: EdgeInsets.only(right: 16.w),
                                child: _buildGameOption(
                                  icon: "assets/icons/greedy_icon.png",
                                  label: game.title,
                                  isLoading:
                                      _isStartingGame &&
                                      _currentGameTitle == game.title,
                                  onTap: () async {
                                    setState(() {
                                      _isStartingGame = true;
                                      _currentGameTitle = game.title;
                                    });

                                    // Show loading snackbar
                                    // ScaffoldMessenger.of(context).showSnackBar(
                                    //   SnackBar(
                                    //     content: Text(
                                    //       '🚀 Starting ${game.title}...',
                                    //     ),
                                    //     backgroundColor: Colors.blue,
                                    //     duration: const Duration(seconds: 2),
                                    //   ),
                                    // );
                                    debugPrint('🚀 Starting ${game.title}...');

                                    setState(() {
                                      _activeGame = game;
                                      _isStartingGame = false;
                                      _currentGameTitle = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                SizedBox(height: 12.h),

                // Control Options Grid
                if (widget.isHost)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16.w, 
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 0.8,
                        children: [
                          _buildControlOption(
                            iconPath: "assets/icons/share_grid_icon.png",
                            label: 'Share',
                            onTap: () {
                              Navigator.pop(context);
                              // Handle share
                            },
                          ),
                          _buildControlOption(
                            iconPath: "assets/icons/coin_grid_icon.png",
                            label: 'Coin Bag',
                            onTap: () {
                              Navigator.pop(context);
                              // Handle coin bag
                            },
                          ),
                         
                          _buildControlOption(
                            iconPath: "assets/icons/camera_flip_grid_icon.png",
                            label: 'Flip Camera',
                            onTap: () {
                              Navigator.pop(context);
                              // Handle flip camera
                            },
                          ),
                         
                          _buildControlOption(
                            iconPath: "assets/icons/beauty_cam_grid_icon.png",
                            label: 'Beauty Camera',
                            onTap: () {
                              Navigator.pop(context);
                              // Handle beauty camera
                            },
                          ),
                           _buildControlOption(
                            iconPath: "assets/icons/music_grid_icon.png",
                            label: 'Music',
                            onTap: () {
                              Navigator.pop(context);
                              // Handle music
                            },
                          ),
                           _buildControlOption(
                            iconPath: "assets/icons/chat_clear_grid_icon.png",
                            label: 'Chat Clear',
                            onTap: () {
                              Navigator.pop(context);
                              // Handle chat clear
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Game overlay (slides up from bottom)
        if (_activeGame != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: MediaQuery.of(context).size.height * gameHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                child: Stack(
                  children: [
                    LocalGamePage(
                      gameTitle: _activeGame!.title,
                      gameId: _activeGame!.id,
                      userId: widget.userId ?? '2ufXoAdqAY',
                    ),
                    // Close button overlay
                    // Positioned(
                    //   top: 16.h,
                    //   right: 16.w,
                    //   child: GestureDetector(
                    //     onTap: () {
                    //       setState(() {
                    //         _activeGame = null;
                    //       });
                    //     },
                    //     child: Container(
                    //       width: 40.w,
                    //       height: 40.h,
                    //       decoration: BoxDecoration(
                    //         color: Colors.black.withOpacity(0.7),
                    //         borderRadius: BorderRadius.circular(20.r),
                    //         border: Border.all(
                    //           color: Colors.white.withOpacity(0.3),
                    //           width: 1,
                    //         ),
                    //       ),
                    //       child: Icon(
                    //         Icons.close,
                    //         color: Colors.white,
                    //         size: 24.sp,
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    // Handle bar for easy closing
                    Positioned(
                      top: 8.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeGame = null;
                            });
                          },
                          child: Container(
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameOption({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 120.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          children: [
            if (isLoading)
              SizedBox(
                width: 32.sp,
                height: 32.sp,
                child: const CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 2,
                ),
              )
            else
              Image.asset(icon, width: 32.sp, height: 32.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF202020),
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlOption({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              // color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Image.asset(iconPath, width: 30.sp, height: 30.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF202020),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
