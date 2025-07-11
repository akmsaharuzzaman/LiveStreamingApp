import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2D5A),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live / Party Live Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // GestureDetector(
                  //   onTap: () {
                  //     context.go('/');
                  //   },
                  //   child: Container(
                  //     width: 40.w,
                  //     height: 40.h,
                  //     decoration: BoxDecoration(
                  //       color: Colors.white.withValues(alpha: 0.1),
                  //       borderRadius: BorderRadius.circular(20.r),
                  //       border: Border.all(
                  //         color: Colors.white.withValues(alpha: 0.3),
                  //         width: 1,
                  //       ),
                  //     ),
                  //     child: Icon(
                  //       Icons.arrow_back_ios_new,
                  //       color: Colors.white,
                  //       size: 18.sp,
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(width: 12.w),
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
                height: 80.h,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 75.w,
                      height: 75.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Image.asset(
                        'assets/images/image_placeholder.png',
                        width: 75.w,
                        height: 75.h,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
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
                        ],
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
                  _buildCategoryButton('Music', selectedCategory == 'Music'),
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
                            color: Colors.white.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8.r),
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
                              color: Colors.white.withOpacity(0.5),
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
                      onTap: () {},
                    ),
                    _buildActionButton(
                      icon: "assets/icons/beauty_icon.png",
                      label: 'Beauty',
                      onTap: () {},
                    ),
                  ],
                ),

                SizedBox(height: 30.h),
              ],

              // Go Live Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    context.push(AppRoutes.onGoingLive);
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
            width: 2,
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
            width: 2,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
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

  @override
  void dispose() {
    _titleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
