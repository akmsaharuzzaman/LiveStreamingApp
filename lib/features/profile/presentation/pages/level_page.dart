import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class LevelPage extends StatefulWidget {
  const LevelPage({super.key});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedLevelRange = 0; // 0: 1-5, 1: 6-10, 2: 11-15, etc.

  final List<String> levelRanges = [
    'Level 1-5',
    'Level 6-10',
    'Level 11-15',
    'Level 16-20',
    'Level 21-25',
    'Level 26-30',
    'Level 31-35',
    'Level 36-40',
  ];

  final List<String> levelRangeAssets = [
    'assets/icons/lv1-5.png',
    'assets/icons/lv6-10.png',
    'assets/icons/lv11-15.png',
    'assets/icons/lv16-20.png',
    'assets/icons/lv21-25.png',
    'assets/icons/lv26-30.png',
    'assets/icons/lv31-35.png',
    'assets/icons/lv36-40.png',
  ];

  final List<Color> levelRangeColors = [
    const Color(0xFFB8860B), // Golden brown for 1-5
    const Color(0xFF9370DB), // Medium purple for 6-10
    const Color(0xFFDC143C), // Crimson for 11-15
    const Color(0xFF00BFFF), // Deep sky blue for 16-20
    const Color(0xFF8A2BE2), // Blue violet for 21-25
    const Color(0xFF4682B4), // Steel blue for 26-30
    const Color(0xFF9370DB), // Medium purple for 31-35
    const Color(0xFF8A2BE2), // Blue violet for 36-40
  ];

  // Level data structure
  final Map<int, String> levelRechargeValues = {
    1: "1 lakh",
    2: "3 lakh",
    3: "5 lakh",
    4: "10 lakh",
    5: "15 lakh",
    6: "21 lakh",
    7: "30 lakh",
    8: "42 lakh",
    9: "55 lakh",
    10: "70 lakh",
    11: "100 lakh",
    12: "150 lakh",
    13: "250 lakh",
    14: "500 lakh",
    15: "1000 lakh",
    16: "2000 lakh",
    17: "4000 lakh",
    18: "8000 lakh",
    19: "15000 lakh",
    20: "30000 lakh",
    21: "50000 lakh",
    22: "10,0000 lakh",
    23: "20,0000 lakh",
    24: "40,0000 lakh",
    25: "80,0000 lakh",
    26: "15,00000 lakh",
    27: "25,00000 lakh",
    28: "40,00000 lakh",
    29: "70,00000 lakh",
    30: "150,00000 lakh",
    31: "200,00000 lakh",
    32: "250,00000 lakh",
    33: "300,00000 lakh",
    34: "350,00000 lakh",
    35: "400,00000 lakh",
    36: "700,00000 lakh",
    37: "1200,00000 lakh",
    38: "2200,00000 lakh",
    39: "4400,00000 lakh",
    40: "10000,00000 lakh",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              Color(0xFF9333EA), // Slightly darker purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Level Badge and Progress
              _buildLevelDisplay(),

              // Tab Section
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 30.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4FF), // Light purple background
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tab Bar
                      _buildTabBar(),

                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildUserLevelTab(),
                            _buildHostLevelTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 15.w),
              Text(
                'My Level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _showLevelRules(),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.help_outline, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDisplay() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // Level Badge
          Container(
            width: 120.w,
            height: 120.w,
            child: Image.asset(
              'assets/icons/lv1-5.png', // Current user level icon
              fit: BoxFit.contain,
            ),
          ),

          SizedBox(height: 20.h),

          // Progress Text
          Text(
            '500k / 1M',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 15.h),

          // Progress Bar
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lv 1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Lv 5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: LinearProgressIndicator(
                    value: 0.5, // 50% progress
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFFFD700), // Gold color
                    ),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: const Color(0xFF8B5CF6),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'User Level'),
          Tab(text: 'Host Level'),
        ],
      ),
    );
  }

  Widget _buildUserLevelTab() {
    return Column(
      children: [
        // Level Range Selector
        _buildLevelRangeSelector(),

        SizedBox(height: 20.h),

        // Level Icons Grid
        Expanded(child: _buildLevelIconsGrid()),
      ],
    );
  }

  Widget _buildHostLevelTab() {
    return Center(
      child: Text(
        'Host Level Content Coming Soon',
        style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildLevelRangeSelector() {
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: levelRanges.length,
        itemBuilder: (context, index) {
          final isSelected = selectedLevelRange == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedLevelRange = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 10.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? levelRangeColors[index] : Colors.grey[300],
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Text(
                levelRanges[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelIconsGrid() {
    // Calculate which levels to show based on selected range
    int startLevel = (selectedLevelRange * 5) + 1;
    int endLevel = (selectedLevelRange + 1) * 5;

    // For this example, show 2 icons per row
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 30.h,
        crossAxisSpacing: 40.w,
        childAspectRatio: 0.8,
      ),
      itemCount: endLevel <= 10
          ? 2
          : 1, // Show 2 items for first two ranges, 1 for others
      itemBuilder: (context, index) {
        if (selectedLevelRange == 0) {
          // Show Lv 1-5 and Lv 6-10 for first selection
          return _buildLevelIcon(
            icon: index == 0
                ? 'assets/icons/lv1-5.png'
                : 'assets/icons/lv6-10.png',
            label: index == 0 ? 'Lv 1-5' : 'Lv 6-10',
            color: index == 0 ? levelRangeColors[0] : levelRangeColors[1],
          );
        } else {
          // Show selected range icon
          return _buildLevelIcon(
            icon: levelRangeAssets[selectedLevelRange],
            label: 'Lv ${startLevel}-${endLevel}',
            color: levelRangeColors[selectedLevelRange],
          );
        }
      },
    );
  }

  Widget _buildLevelIcon({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          child: Image.asset(icon, fit: BoxFit.contain),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showLevelRules() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LevelRulesPage()),
    );
  }
}

// Level Rules Page
class LevelRulesPage extends StatelessWidget {
  const LevelRulesPage({super.key});

  final Map<int, String> levelRechargeValues = const {
    1: "1 lakh",
    2: "3 lakh",
    3: "5 lakh",
    4: "10 lakh",
    5: "15 lakh",
    6: "21 lakh",
    7: "30 lakh",
    8: "42 lakh",
    9: "55 lakh",
    10: "70 lakh",
    11: "100 lakh",
    12: "150 lakh",
    13: "250 lakh",
    14: "500 lakh",
    15: "1000 lakh",
    16: "2000 lakh",
    17: "4000 lakh",
    18: "8000 lakh",
    19: "15000 lakh",
    20: "30000 lakh",
    21: "50000 lakh",
    22: "10,0000 lakh",
    23: "20,0000 lakh",
    24: "40,0000 lakh",
    25: "80,0000 lakh",
    26: "15,00000 lakh",
    27: "25,00000 lakh",
    28: "40,00000 lakh",
    29: "70,00000 lakh",
    30: "150,00000 lakh",
    31: "200,00000 lakh",
    32: "250,00000 lakh",
    33: "300,00000 lakh",
    34: "350,00000 lakh",
    35: "400,00000 lakh",
    36: "700,00000 lakh",
    37: "1200,00000 lakh",
    38: "2200,00000 lakh",
    39: "4400,00000 lakh",
    40: "10000,00000 lakh",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20.sp),
        ),
        title: Text(
          'Level Rules',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 15.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.r),
                  topRight: Radius.circular(15.r),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      decoration: const BoxDecoration(color: Color(0xFF666666)),
                      child: Text(
                        'Level',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      decoration: const BoxDecoration(color: Color(0xFFB8860B)),
                      child: Text(
                        'Recharge Value',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Content
            Expanded(
              child: ListView.builder(
                itemCount: levelRechargeValues.length,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final value = levelRechargeValues[level]!;
                  final isEven = index % 2 == 0;

                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFF8F4FF),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Text(
                              'Level $level',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
