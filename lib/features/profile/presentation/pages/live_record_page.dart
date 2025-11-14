import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/network/api_service.dart';

class LiveRecordPage extends StatefulWidget {
  final UserModel? user;

  const LiveRecordPage({super.key, this.user});

  @override
  State<LiveRecordPage> createState() => _LiveRecordPageState();
}

class _LiveRecordPageState extends State<LiveRecordPage> {
  final ApiService _apiService = ApiService();
  late ApiResult response;
  int dayCount = 0;
  int hourCount = 0;
  int audioHour = 0;
  int videoHour = 0;
  int withdrawBonus = 0;

  @override
  void initState() {
    super.initState();
    getLiveRecord();
    getWithdrawBonus();
  }

  void getLiveRecord() async {
    try {
      var response = await _apiService.get(
        '/api/auth/live-count/${widget.user?.id}',
      );
      debugPrint("\n \n ${response.dataOrNull.toString()} \n \n");
      setState(() {
        this.response = response;
        dayCount = response.dataOrNull?["result"]["dayCount"] ?? 0;
        hourCount = response.dataOrNull?["result"]["hourCount"] ?? 0;
        audioHour = response.dataOrNull?["result"]["audioHour"] ?? 0;
        videoHour = response.dataOrNull?["result"]["videoHour"] ?? 0;
        // debugPrint("\n \n dayCount: $dayCount , hourCount: $hourCount , audioHour: $audioHour , videoHour: $videoHour \n \n");
      });
    } catch (e) {
      setState(() {
        response = ApiResult.failure(e.toString());
      });
    }
  }

  Future<void> getWithdrawBonus() async {
    try {
      final bonusResponse = await _apiService.get('/api/auth/withdraw-bonus');
      final bonus = bonusResponse.dataOrNull?['result']?['bonus'] ?? 0;
      if (!mounted) return;
      setState(() {
        withdrawBonus = bonus is num ? bonus.toInt() : 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        withdrawBonus = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        // title: Text(
        //   'Classy',
        //   style: TextStyle(
        //     color: Colors.black,
        //     fontSize: 18.sp,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        centerTitle: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Text(
                'Records',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            // Main Earnings Display
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10.r,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.diamond,
                        color: const Color(0xFF00BCD4),
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppUtils.formatNumber(
                          (widget.user?.stats?.diamonds ?? 0) + withdrawBonus,
                        ),
                        style: TextStyle(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This Month',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF999999),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Statistics Row
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10.r,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Actual Earnings
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.diamond,
                              color: const Color(0xFF00BCD4),
                              size: 16.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '+${AppUtils.formatNumber(widget.user?.stats?.diamonds ?? 0)}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Actual Earnings',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Video Live Duration
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12.w,
                              height: 12.h,
                              decoration: const BoxDecoration(
                                color: Color(0xFF666666),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              videoHour.toString(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Video live duration',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Audio Live Duration
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12.w,
                              height: 12.h,
                              decoration: const BoxDecoration(
                                color: Color(0xFF666666),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              audioHour.toString(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Audio live duration',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Valid days
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12.w,
                              height: 12.h,
                              decoration: const BoxDecoration(
                                color: Color(0xFF666666),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              dayCount.toString(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Valid days',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress Timeline
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  // Start point
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BCD4),
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Progress line
                  Expanded(
                    child: Container(
                      height: 2.h,
                      color: const Color(0xFFE0E0E0),
                      child: Row(
                        children: [
                          Container(
                            width: 1, // No progress
                            height: 2.h,
                            color: const Color(0xFF00BCD4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // End point
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Options List
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10.r,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildOptionItem(
                    'Bonuses',
                    '+${AppUtils.formatNumber(withdrawBonus)}',
                    const Color(0xFF00BCD4),
                    true,
                  ),
                  _buildDivider(),
                  _buildOptionItem(
                    'Exchange',
                    '-0',
                    const Color(0xFF00BCD4),
                    true,
                  ),
                  _buildDivider(),
                  _buildOptionItem(
                    'Others',
                    '0',
                    const Color(0xFF00BCD4),
                    true,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // FAQ Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10.r,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  _buildFAQItem('How to calculate monthly earnings?'),
                  SizedBox(height: 16.h, width: double.infinity),
                  _buildFAQItem('How to calculate Basic salary?'),
                  SizedBox(height: 20.h),
                  Text(
                    'Note:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Note content would go here if provided
                ],
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    String title,
    String value,
    Color valueColor,
    bool showArrow,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.diamond, color: valueColor, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (showArrow) ...[
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF999999),
                  size: 14.sp,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      color: const Color(0xFFF0F0F0),
    );
  }

  Widget _buildFAQItem(String question) {
    return Text(
      question,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
    );
  }
}
