import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dlstarlive/core/utils/permission_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deepar_flutter_perfect/deepar_flutter_perfect.dart';
import 'dart:io';
import 'dart:async';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  bool isLiveSelected = true; // true for Live, false for Party Live
  String selectedCategory = "Song";
  String selectedPeopleCount = "8 People";
  bool isPasswordEnabled = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Camera related variables
  bool _isFrontCamera = true;
  bool _isInitializingCamera = false;

  // DeepAR related variables
  final DeepArControllerPerfect _deepArController = DeepArControllerPerfect();
  bool _isDeepArInitialized = false;
  String? _currentEffect;

  // Available effects list
  final List<String> _availableEffects = [
    'assets/effects/flower_face.deepar',
    'assets/effects/Fire_Effect.deepar',
    'assets/effects/Neon_Devil_Horns.deepar',
    'assets/effects/MakeupLook.deepar',
    'assets/effects/viking_helmet.deepar',
    'assets/effects/Pixel_Hearts.deepar',
  ];

  @override
  void initState() {
    super.initState();
    _initializeWithPermissions();
  }

  Future<void> _initializeWithPermissions() async {
    try {
      setState(() {
        _isInitializingCamera = true;
      });

      // First, ensure we have permissions before initializing anything
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

      // Load camera preference
      final prefs = await SharedPreferences.getInstance();
      _isFrontCamera = prefs.getBool('is_front_camera') ?? true;
      debugPrint(
        '🔍 Loaded camera preference: ${_isFrontCamera ? 'Front' : 'Rear'} camera',
      );

      // Initialize only DeepAR after permissions are granted
      await _initializeDeepAR();
    } catch (e) {
      debugPrint('Error during initialization: $e');
      setState(() {
        _isInitializingCamera = false;
      });
    }
  }

  Future<void> _initializeDeepAR() async {
    try {
      final androidKey = dotenv.env['DEEPAR_ANDROID_LICENSE_KEY'] ?? '';
      final iosKey = dotenv.env['DEEPAR_IOS_LICENSE_KEY'] ?? '';

      final result = await _deepArController.initialize(
        androidLicenseKey: androidKey,
        iosLicenseKey: iosKey,
        resolution: Resolution.medium,
      );

      if (result.success) {
        debugPrint("DeepAR initialized successfully: ${result.message}");

        if (Platform.isIOS) {
          Timer.periodic(Duration(milliseconds: 500), (timer) {
            if (_deepArController.isInitialized) {
              debugPrint('iOS DeepAR view fully initialized');
              setState(() {
                _isDeepArInitialized = true;
                _isInitializingCamera = false;
              });
              timer.cancel();
            } else if (timer.tick > 20) {
              debugPrint('Timeout waiting for iOS DeepAR view initialization');
              setState(() {
                _isInitializingCamera = false;
              });
              timer.cancel();
            }
          });
        } else {
          setState(() {
            _isDeepArInitialized = true;
            _isInitializingCamera = false;
          });
        }
      } else {
        debugPrint("DeepAR initialization failed: ${result.message}");
        setState(() {
          _isInitializingCamera = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing DeepAR: $e');
      setState(() {
        _isInitializingCamera = false;
      });
    }
  }

  Future<void> _flipCamera() async {
    if (!_isDeepArInitialized) return;

    try {
      // DeepAR camera flip - the SDK should handle this internally
      debugPrint('🔄 Flipping camera in DeepAR mode');

      // Try to call DeepAR's flip camera method if it exists
      // According to docs, some versions have flipCamera() method
      try {
        // This might not be available in all versions, so we wrap in try-catch
        await _deepArController.flipCamera();
        debugPrint('✅ DeepAR flip camera called successfully');
      } catch (e) {
        debugPrint('⚠️ DeepAR flipCamera method not available: $e');
        // If DeepAR doesn't have flipCamera, just update our state
      }

      // Toggle camera preference for consistency with go live screen
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });

      // Save camera preference for go live screen
      await _saveCameraPreference(_isFrontCamera);
      debugPrint(
        'Camera preference updated to ${_isFrontCamera ? 'front' : 'back'}',
      );
    } catch (e) {
      debugPrint('Error flipping camera: $e');
    }
  }

  Future<void> _saveCameraPreference(bool isFrontCamera) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_front_camera', isFrontCamera);

      // Verify the save was successful
      bool saved = prefs.getBool('is_front_camera') ?? true;
      debugPrint(
        '💾 Saved camera preference: ${isFrontCamera ? 'Front' : 'Rear'} camera',
      );
      debugPrint(
        '✅ Verification - Stored value: ${saved ? 'Front' : 'Rear'} camera',
      );

      if (saved != isFrontCamera) {
        debugPrint('⚠️ Warning: Camera preference save verification failed!');
      }
    } catch (e) {
      debugPrint('❌ Error saving camera preference: $e');
    }
  }

  Future<void> _switchDeepArEffect(String effectPath) async {
    if (!_isDeepArInitialized) return;

    try {
      await _deepArController.switchEffect(effectPath);
      setState(() {
        _currentEffect = effectPath;
      });
      debugPrint('Switched to effect: $effectPath');
    } catch (e) {
      debugPrint('Error switching DeepAR effect: $e');
    }
  }

  Future<void> _clearDeepArEffect() async {
    if (!_isDeepArInitialized) return;

    try {
      // Clear the UI state
      setState(() {
        _currentEffect = null;
      });
      debugPrint('DeepAR effect cleared from UI state');
    } catch (e) {
      debugPrint('Error clearing DeepAR effect: $e');
      setState(() {
        _currentEffect = null;
      });
    }
  }

  Widget _buildDeepArPreview() {
    if (!_isDeepArInitialized || !_deepArController.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing AR Camera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return DeepArPreviewPerfect(_deepArController);
  }

  Widget _buildCameraPreview() {
    if (_isInitializingCamera) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Always show DeepAR preview
    return _buildDeepArPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview as background
          Positioned.fill(child: _buildCameraPreview()),

          // Dark overlay for better content visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
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
                  // Live / Party Live Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isLiveSelected = true;
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
                                color: isLiveSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              child: Center(
                                child: Text(
                                  'Live',
                                  style: TextStyle(
                                    color: isLiveSelected
                                        ? Colors.black
                                        : Colors.white,
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
                          onTap: () {
                            setState(() {
                              isLiveSelected = false;
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
                                color: !isLiveSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              child: Center(
                                child: Text(
                                  'Party Live',
                                  style: TextStyle(
                                    color: !isLiveSelected
                                        ? Colors.black
                                        : Colors.white,
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
                      border: Border.all(
                        width: 2.w,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/image_holder.png',
                          width: 75.w,
                          height: 75.h,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              hintText: 'Add a title',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16.sp,
                              ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Category Selection
                  Row(
                    children: [
                      _buildCategoryButton('Song', selectedCategory == 'Song'),
                      SizedBox(width: 16.w),
                      _buildCategoryButton(
                        'Music',
                        selectedCategory == 'Music',
                      ),
                    ],
                  ),

                  // Show additional options for Party Live
                  if (!isLiveSelected) ...[
                    SizedBox(height: 30.h),

                    // Category (People Count)
                    Text(
                      'Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // People Count Selection
                    Row(
                      children: [
                        _buildPeopleButton(
                          '8 People',
                          selectedPeopleCount == '8 People',
                        ),
                        SizedBox(width: 12.w),
                        _buildPeopleButton(
                          '12 People',
                          selectedPeopleCount == '12 People',
                        ),
                        SizedBox(width: 12.w),
                        _buildPeopleButton(
                          '16 People',
                          selectedPeopleCount == '16 People',
                        ),
                      ],
                    ),

                    SizedBox(height: 30.h),

                    // Password Section
                    Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50.h,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1.w,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              enabled: isPasswordEnabled,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Password',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16.sp,
                                ),
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
                              color: isPasswordEnabled
                                  ? const Color(0xFFFF69B4)
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: isPasswordEnabled
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 24.w,
                                height: 24.h,
                                margin: EdgeInsets.all(2.w),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
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
                        _buildActionButton(
                          icon: "assets/icons/beauty_icon.png",
                          label: 'Beauty AR',
                          onTap:
                              () {}, // Just a label now, no toggle functionality
                        ),
                      ],
                    ),

                    // AR Effects Row (always show when DeepAR is initialized)
                    if (_isDeepArInitialized) ...[
                      SizedBox(height: 20.h),
                      Container(
                        height: 80.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              _availableEffects.length +
                              1, // +1 for clear effect
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // Clear effect button
                              return _buildEffectButton(
                                effectPath: "",
                                isSelected: _currentEffect == null,
                                label: "Clear",
                                onTap: _clearDeepArEffect,
                              );
                            }

                            final effectPath = _availableEffects[index - 1];
                            final effectName = effectPath
                                .split('/')
                                .last
                                .split('.')
                                .first;

                            return _buildEffectButton(
                              effectPath: effectPath,
                              isSelected: _currentEffect == effectPath,
                              label: effectName,
                              onTap: () => _switchDeepArEffect(effectPath),
                            );
                          },
                        ),
                      ),
                    ],

                    SizedBox(height: 30.h),
                  ],

                  // Go Live Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () async {
                        print(
                          "Going live with title: ${_isFrontCamera ? 'Front Camera' : 'Back Camera'}",
                        );

                        // Ensure camera preference is saved before navigation
                        await _saveCameraPreference(_isFrontCamera);
                        debugPrint(
                          '🚀 Navigating to go live with camera: ${_isFrontCamera ? 'Front' : 'Rear'}',
                        );

                        // Small delay to ensure SharedPreferences write completes
                        await Future.delayed(const Duration(milliseconds: 100));

                        if (mounted) {
                          context.push(AppRoutes.onGoingLive);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF85A3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Go Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
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
          border: Border.all(
            width: 2.w,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
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
          border: Border.all(
            width: 2.w,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
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

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(icon, color: Colors.white, width: 48.sp, height: 48.sp),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectButton({
    required String effectPath,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF85A3)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF85A3)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2.w,
                ),
              ),
              child: Icon(
                effectPath.isEmpty
                    ? Icons.clear
                    : Icons.face_retouching_natural,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _passwordController.dispose();

    // DeepAR controller will be cleaned up automatically
    super.dispose();
  }
}
