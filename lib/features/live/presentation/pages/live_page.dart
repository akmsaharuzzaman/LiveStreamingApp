import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dlstarlive/core/utils/permission_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  bool isLiveSelected = true; // true for Live, false for Audio Live
  String selectedCategory = "Song";
  String selectedPeopleCount = "6 People";
  bool isPasswordEnabled = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Camera related variables
  RtcEngine? _engine;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;
  bool _isInitializingCamera = false;

  @override
  void initState() {
    super.initState();
    // Only initialize camera for Live mode, not Audio Live
    if (isLiveSelected) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializingCamera = true;
      });

      // Load camera preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _isFrontCamera = prefs.getBool('is_front_camera') ?? true;
      debugPrint('🔍 Loaded camera preference: ${_isFrontCamera ? 'Front' : 'Rear'} camera');

      // Check permissions
      bool hasPermissions = await PermissionHelper.hasLiveStreamPermissions();
      if (!hasPermissions) {
        bool granted = await PermissionHelper.requestLiveStreamPermissions();
        if (!granted) {
          setState(() {
            _isInitializingCamera = false;
          });
          return;
        }
      }

      // Initialize Agora engine
      final engine = createAgoraRtcEngine();
      await engine.initialize(
        RtcEngineContext(
          appId: dotenv.env['AGORA_APP_ID'] ?? '',
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      // Apply the saved camera preference after preview starts
      if (!_isFrontCamera) {
        await engine.switchCamera();
        debugPrint('🔄 Applied saved camera preference: Rear camera');
      } else {
        debugPrint('🔄 Applied saved camera preference: Front camera');
      }

      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.enableVideo();
      await engine.startPreview();

      setState(() {
        _engine = engine;
        _isCameraInitialized = true;
        _isInitializingCamera = false;
      });

      // Don't save preference here since we're just applying the loaded one
      // await _saveCameraPreference(_isFrontCamera);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      setState(() {
        _isInitializingCamera = false;
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_isCameraInitialized) {
      try {
        final engine = _engine;
        if (engine == null) return;
        await engine.switchCamera();
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
        debugPrint('Camera flipped to ${_isFrontCamera ? 'front' : 'back'}');

        // Save camera preference
        await _saveCameraPreference(_isFrontCamera);
      } catch (e) {
        debugPrint('Error flipping camera: $e');
      }
    }
  }

  Future<void> _saveCameraPreference(bool isFrontCamera) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_front_camera', isFrontCamera);

      // Verify the save was successful
      bool saved = prefs.getBool('is_front_camera') ?? true;
      debugPrint('💾 Saved camera preference: ${isFrontCamera ? 'Front' : 'Rear'} camera');
      debugPrint('✅ Verification - Stored value: ${saved ? 'Front' : 'Rear'} camera');

      if (saved != isFrontCamera) {
        debugPrint('⚠️ Warning: Camera preference save verification failed!');
      }
    } catch (e) {
      debugPrint('❌ Error saving camera preference: $e');
    }
  }

  Widget _buildCameraPreview() {
    if (_isInitializingCamera) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Camera not available',
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
        ),
      );
    }

    final engine = _engine;
    if (engine == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Camera not available',
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
    );
  }

  Future<void> _disposeCamera() async {
    final engine = _engine;
    if (engine == null && !_isCameraInitialized && !_isInitializingCamera) {
      return;
    }

    try {
      if (_isCameraInitialized && engine != null) {
        await engine.stopPreview();
        await engine.leaveChannel();
      }
      if (engine != null) {
        await engine.release();
      }
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    } finally {
      if (mounted) {
        setState(() {
          _engine = null;
          _isCameraInitialized = false;
          _isInitializingCamera = false;
        });
      } else {
        _engine = null;
        _isCameraInitialized = false;
        _isInitializingCamera = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview as background (only for Live mode)
          if (isLiveSelected)
            Positioned.fill(child: _buildCameraPreview())
          else
            // Audio Live background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B46C1), Color(0xFF2D3748)],
                  ),
                ),
                child: Image.asset(
                  'assets/icons/audio_room/audio_room_background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF6B46C1), Color(0xFF2D3748)],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Dark overlay for better content visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),

          // Flip camera button
          // Positioned(
          //   top: 60.h,
          //   right: 16.w,
          //   child: GestureDetector(
          //     onTap: _flipCamera,
          //     child: Container(
          //       width: 40.w,
          //       height: 40.w,
          //       decoration: BoxDecoration(
          //         color: Colors.black.withValues(alpha:0.5),
          //         shape: BoxShape.circle,
          //         border: Border.all(
          //           color: Colors.white.withValues(alpha:0.3),
          //           width: 1,
          //         ),
          //       ),
          //       child: Icon(
          //         Icons.flip_camera_ios,
          //         color: Colors.white,
          //         size: 20.sp,
          //       ),
          //     ),
          //   ),
          // ),

          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live / Audio Live Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isLiveSelected = true;
                              // Initialize camera when switching to Live mode
                              if (!_isCameraInitialized && !_isInitializingCamera) {
                                _initializeCamera();
                              }
                            });
                          },
                          child: Container(
                            height: 33.h,
                            width: 93.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Container(
                              height: 50.h,
                              decoration: BoxDecoration(
                                color: isLiveSelected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              child: Center(
                                child: Text(
                                  'Live',
                                  style: TextStyle(
                                    color: isLiveSelected ? Colors.black : Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 72.w),
                      Center(
                        child: InkWell(
                          onTap: () async {
                            if (isLiveSelected) {
                              await _disposeCamera();
                            }
                            if (mounted) {
                              setState(() {
                                isLiveSelected = false;
                              });
                            }
                          },
                          child: Container(
                            height: 33.h,
                            width: 93.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Container(
                              height: 50.h,
                              decoration: BoxDecoration(
                                color: !isLiveSelected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              child: Center(
                                child: Text(
                                  'Audio Live',
                                  style: TextStyle(
                                    color: !isLiveSelected ? Colors.black : Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40.h),

                  // Title Input Section
                  Container(
                    height: 85.h,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      border: Border.all(width: 2.w, color: Colors.white.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/image_holder.png', width: 75.w, height: 75.h),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            style: TextStyle(color: Colors.white, fontSize: 16.sp),
                            decoration: InputDecoration(
                              filled: false,
                              hintText: 'Add a title',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16.sp),
                              hintMaxLines: 2,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Select Category
                  Text(
                    'Select Category',
                    style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w500),
                  ),

                  SizedBox(height: 16.h),

                  // Category Selection
                  Row(
                    children: [
                      _buildCategoryButton('Song', selectedCategory == 'Song'),
                      SizedBox(width: 16.w),
                      _buildCategoryButton('Music', selectedCategory == 'Music'),
                    ],
                  ),

                  // Show additional options for Audio Live
                  if (!isLiveSelected) ...[
                    SizedBox(height: 30.h),

                    // Category (People Count)
                    Text(
                      'Category',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),

                    SizedBox(height: 16.h),

                    // People Count Selection
                    Row(
                      children: [
                        _buildPeopleButton('6 People', selectedPeopleCount == '6 People'),
                        SizedBox(width: 12.w),
                        _buildPeopleButton('8 People', selectedPeopleCount == '8 People'),
                        SizedBox(width: 12.w),
                        _buildPeopleButton('12 People', selectedPeopleCount == '12 People'),
                      ],
                    ),

                    SizedBox(height: 30.h),

                    // Password Section
                    Text(
                      'Password',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),

                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50.h,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              border: Border.all(width: 1.w, color: Colors.white.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(8.r),
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              enabled: isPasswordEnabled,
                              style: TextStyle(color: Colors.white, fontSize: 16.sp),
                              decoration: InputDecoration(
                                hintText: 'Enter Password',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16.sp),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isPasswordEnabled = !isPasswordEnabled;
                            });
                          },
                          child: Container(
                            width: 50.w,
                            height: 28.h,
                            decoration: BoxDecoration(
                              color: isPasswordEnabled ? const Color(0xFFFF69B4) : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: isPasswordEnabled ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: 24.w,
                                height: 24.h,
                                margin: EdgeInsets.all(2.w),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Bottom Action Buttons (only for Live mode)
                  if (isLiveSelected) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: "assets/icons/camera_icon.png",
                          label: 'Flip Camera',
                          onTap: _flipCamera,
                        ),
                        _buildActionButton(icon: "assets/icons/beauty_icon.png", label: 'Beauty', onTap: () {}),
                      ],
                    ),

                    SizedBox(height: 30.h),
                  ],

                  // @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                  // ########################## Go Live Button ##########################
                  // @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (isLiveSelected) {
                          // ########################## Live mode ##########################
                          print("Going live with title: ${_isFrontCamera ? 'Front Camera' : 'Back Camera'}");

                          // Ensure camera preference is saved before navigation
                          await _saveCameraPreference(_isFrontCamera);
                          debugPrint('🚀 Navigating to go live with camera: ${_isFrontCamera ? 'Front' : 'Rear'}');

                          // Small delay to ensure SharedPreferences write completes
                          await Future.delayed(const Duration(milliseconds: 100));

                          if (mounted) {
                            context.push(AppRoutes.onGoingLive);
                          }
                        } else {
                          // ########################## Audio Live mode ##########################
                          // Extract number from selectedPeopleCount (e.g., "6 People" -> 6)
                          int numberOfSeats = int.parse(selectedPeopleCount.split(' ').first);

                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthUnauthenticated) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('User is not authenticated')));
                            return;
                          }
                          if (authState is AuthAuthenticated) {
                            if (authState.user.id.isEmpty) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('User ID is empty')));
                              return;
                            }
                            final userId = authState.user.id;
                            debugPrint("🚀 Navigating to audio live with userId: $userId as Host");
                            context.push(
                              AppRoutes.audioLive,
                              extra: {
                                'isHost': true,
                                'roomId': "audio_room_$userId",
                                'numberOfSeats': numberOfSeats,
                                'title': _titleController.text.isEmpty ? 'Audio Room' : _titleController.text,
                                'roomDetails': null,
                                // userId
                                'userId': userId,
                              },
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF85A3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Go Live',
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = text;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(width: 2.w, color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPeopleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeopleCount = text;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(width: 2.w, color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(icon, color: Colors.white, width: 48.sp, height: 48.sp),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _passwordController.dispose();
    // Only dispose camera if it was initialized
    if (_isCameraInitialized) {
      _engine?.leaveChannel();
      _engine?.release();
    }
    super.dispose();
  }
}
