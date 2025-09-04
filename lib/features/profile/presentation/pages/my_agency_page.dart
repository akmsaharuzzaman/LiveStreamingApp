import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';

// Agency model
class AgencyModel {
  final String id;
  final String name;
  final String agencyId;
  final String? avatar;
  final AgencyStatus status;

  AgencyModel({
    required this.id,
    required this.name,
    required this.agencyId,
    this.avatar,
    required this.status,
  });
}

enum AgencyStatus { available, waiting, approved }

class MyAgencyPage extends StatefulWidget {
  final UserModel user;

  const MyAgencyPage({super.key, required this.user});

  @override
  State<MyAgencyPage> createState() => _MyAgencyPageState();
}

class _MyAgencyPageState extends State<MyAgencyPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AgencyModel> agencies = [
    AgencyModel(
      id: '1',
      name: 'BD Agency',
      agencyId: 'ID:123456',
      avatar: null, // Will use default avatar
      status: AgencyStatus.available,
    ),
    // Add more sample agencies as needed
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _joinAgency(AgencyModel agency) {
    setState(() {
      // Update the agency status to waiting
      final index = agencies.indexWhere((a) => a.id == agency.id);
      if (index != -1) {
        agencies[index] = AgencyModel(
          id: agency.id,
          name: agency.name,
          agencyId: agency.agencyId,
          avatar: agency.avatar,
          status: AgencyStatus.waiting,
        );
      }
    });

    // Simulate approval after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showCongratulationsPage(agency);
      }
    });
  }

  void _showCongratulationsPage(AgencyModel agency) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CongratulationsPage(
          agency: agency,
          onContinue: () => _showWelcomePage(agency),
        ),
      ),
    );
  }

  void _showWelcomePage(AgencyModel agency) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WelcomePage(
          agency: agency,
          onFinish: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20.sp),
        ),
        title: Text(
          'Agency',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Search Section
            _buildSearchSection(),

            SizedBox(height: 20.h),

            // Agency List
            Expanded(
              child: agencies.isEmpty
                  ? const Center(child: Text('No agencies found'))
                  : ListView.builder(
                      itemCount: agencies.length,
                      itemBuilder: (context, index) {
                        return _buildAgencyCard(agencies[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            // decoration: BoxDecoration(
            //   color: const Color(0xFFF5F5F5),
            //   borderRadius: BorderRadius.circular(8.r),
            //   border: Border.all(color: Colors.grey[300]!),
            // ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                fillColor: Color(0xFFF5F5F5),
                hintText: 'Search agency ID',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Color(0xFF888686), width: 1.w),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Color(0xFF888686), width: 1.w),
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Color(0xFF888686), width: 1.w),
                ),
                contentPadding: EdgeInsets.all(16.w),
              ),
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Color(0xFF888686)),
          ),
          child: Icon(Icons.search, color: Colors.grey[600], size: 24.sp),
        ),
      ],
    );
  }

  Widget _buildAgencyCard(AgencyModel agency) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAA2), // Yellow background like in screenshot
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Agency Avatar
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: agency.avatar != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(agency.avatar!, fit: BoxFit.cover),
                  )
                : Icon(Icons.business, color: Colors.white, size: 30.sp),
          ),

          SizedBox(width: 16.w),

          // Agency Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agency.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  agency.agencyId,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Action Button
          _buildActionButton(agency),
        ],
      ),
    );
  }

  Widget _buildActionButton(AgencyModel agency) {
    switch (agency.status) {
      case AgencyStatus.available:
        return ElevatedButton(
          onPressed: () => _joinAgency(agency),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF082A7B), // Blue color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          ),
          child: Text(
            'Join',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case AgencyStatus.waiting:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'Waiting',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case AgencyStatus.approved:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'Joined',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }
}

// Congratulations Page
class CongratulationsPage extends StatelessWidget {
  final AgencyModel agency;
  final VoidCallback onContinue;

  const CongratulationsPage({
    super.key,
    required this.agency,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5CF6), // Purple
              Color(0xFF7C3AED), // Darker purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Text(
                      'Agency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E), // Green
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50.sp,
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // Congratulations Text
                    Text(
                      'Congratulations!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 80.h),

                    // Bottom Card
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.all(30.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Approved!',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: 20.h),

                          Text(
                            'Delighted to have you with us.\nLet\'s grow together through collaboration\nand shared success!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: 30.h),

                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: onContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                              ),
                              child: Text(
                                'Best Of Luck!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

// Welcome Page
class WelcomePage extends StatelessWidget {
  final AgencyModel agency;
  final VoidCallback onFinish;

  const WelcomePage({super.key, required this.agency, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5CF6), // Purple
              Color(0xFF7C3AED), // Darker purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Text(
                      'Agency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Wings Image
                    Container(
                      width: 300.w,
                      height: 150.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700), // Gold
                            Color(0xFFFFA500), // Orange
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.star,
                          size: 60.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // Shield Icon
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: const Color(0xFF22C55E),
                        size: 40.sp,
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // Welcome Text
                    Text(
                      'Welcome to DLStar!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Text(
                        'We\'re thrilled to have your agency join the DLStar family. Together, let\'s grow, innovate, and succeed!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          height: 1.5,
                        ),
                      ),
                    ),

                    SizedBox(height: 60.h),

                    // Finish Button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: onFinish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                          ),
                          child: Text(
                            'Let\'s Enjoy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
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
