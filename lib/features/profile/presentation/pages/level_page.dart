import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';

class LevelPage extends StatefulWidget {
  final UserModel? user;

  const LevelPage({super.key, this.user});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedLevelRange = -1; // -1: show all, 0: 1-5, 1: 6-10, etc.

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

  // Host level data structure (receive coin values)
  final Map<int, String> hostLevelReceiveValues = {
    1: "3 lakh",
    2: "9 lakh",
    3: "15 lakh",
    4: "30 lakh",
    5: "45 lakh",
    6: "63 lakh",
    7: "90 lakh",
    8: "126 lakh",
    9: "165 lakh",
    10: "210 lakh",
    11: "300 lakh",
    12: "450 lakh",
    13: "750 lakh",
    14: "1500 lakh",
    15: "3000 lakh",
    16: "6000 lakh",
    17: "12000 lakh",
    18: "24000 lakh",
    19: "45000 lakh",
    20: "90000 lakh",
    21: "150000 lakh",
    22: "30,0000 lakh",
    23: "60,0000 lakh",
    24: "120,0000 lakh",
    25: "240,0000 lakh",
    26: "45,00000 lakh",
    27: "75,00000 lakh",
    28: "120,00000 lakh",
    29: "210,00000 lakh",
    30: "750,00000 lakh",
    31: "600,00000 lakh",
    32: "750,00000 lakh",
    33: "900,00000 lakh",
    34: "150,00000 lakh",
    35: "1200,00000 lakh",
    36: "2100,00000 lakh",
    37: "3600,00000 lakh",
    38: "6600,00000 lakh",
    39: "13200,00000 lakh",
    40: "30000,00000 lakh",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted)
        setState(() {}); // Refresh header/title & progress when tab changes
    });
  }

  // Helper methods to get user data
  int get userCoins => widget.user?.stats?.coins ?? 0;
  int get userLevel => widget.user?.stats?.levels ?? 1;

  String get userLevelIcon {
    if (userLevel <= 5) return 'assets/icons/lv1-5.png';
    if (userLevel <= 10) return 'assets/icons/lv6-10.png';
    if (userLevel <= 15) return 'assets/icons/lv11-15.png';
    if (userLevel <= 20) return 'assets/icons/lv16-20.png';
    if (userLevel <= 25) return 'assets/icons/lv21-25.png';
    if (userLevel <= 30) return 'assets/icons/lv26-30.png';
    if (userLevel <= 35) return 'assets/icons/lv31-35.png';
    return 'assets/icons/lv36-40.png';
  }

  String get progressText {
    final nextLevel = userLevel + 1;
    final nextLevelCoins = levelRechargeValues[nextLevel] ?? "Max";
    return "${_formatCoins(userCoins)} / $nextLevelCoins";
  }

  String _formatCoins(int coins) {
    if (coins >= 10000000) {
      return "${(coins / 10000000).toStringAsFixed(1)}M";
    } else if (coins >= 100000) {
      return "${(coins / 100000).toStringAsFixed(1)}L";
    } else if (coins >= 1000) {
      return "${(coins / 1000).toStringAsFixed(1)}k";
    }
    return coins.toString();
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
                _tabController.index == 0 ? 'My Level' : 'Host Level',
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
              userLevelIcon, // Use actual user level icon
              fit: BoxFit.contain,
            ),
          ),

          SizedBox(height: 20.h),

          // Progress Text
          Text(
            progressText, // Use actual progress
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 15.h),

          // Progress Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final progress = _calculateProgress();
              final trackWidth =
                  constraints.maxWidth -
                  80.w; // account for side margins inside this container
              final knobSize = 14.w;
              final knobOffset =
                  (trackWidth - knobSize).clamp(0, double.infinity) * progress;
              return Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lv $userLevel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Lv ${userLevel + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 16.h,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Track
                          Positioned.fill(
                            left: 0,
                            right: 0,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                          // Knob
                          Positioned(
                            left:
                                knobOffset +
                                40.w, // align with horizontal margin used above
                            child: Container(
                              width: knobSize,
                              height: knobSize,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD700),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    final currentLevelValue = _parseCoins(
      levelRechargeValues[userLevel] ?? "0",
    );
    final nextLevelValue = _parseCoins(
      levelRechargeValues[userLevel + 1] ?? "0",
    );

    if (nextLevelValue <= currentLevelValue) return 1.0;

    final progress =
        (userCoins - currentLevelValue) / (nextLevelValue - currentLevelValue);
    return progress.clamp(0.0, 1.0);
  }

  int _parseCoins(String coinStr) {
    // Simple parser for coin strings like "1 lakh" -> 100000
    final parts = coinStr.toLowerCase().split(' ');
    if (parts.length < 2) return 0;

    final number = double.tryParse(parts[0].replaceAll(',', '')) ?? 0;
    final unit = parts[1];

    switch (unit) {
      case 'lakh':
        return (number * 100000).toInt();
      case 'crore':
        return (number * 10000000).toInt();
      default:
        return number.toInt();
    }
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.only(top: 10.h, left: 20.w, right: 20.w, bottom: 0),
      child: TabBar(
        controller: _tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(width: 3, color: Color(0xFF8B5CF6)),
          insets: EdgeInsets.symmetric(horizontal: 20),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: const Color(0xFF8B5CF6),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 15.sp,
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
        Expanded(child: _buildLevelIconsGrid(isHostLevel: false)),
      ],
    );
  }

  Widget _buildHostLevelTab() {
    return Column(
      children: [
        // Level Range Selector
        _buildLevelRangeSelector(),

        SizedBox(height: 20.h),

        // Level Icons Grid
        Expanded(child: _buildLevelIconsGrid(isHostLevel: true)),
      ],
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
              setState(() => selectedLevelRange = index);
            },
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          levelRangeColors[index].withOpacity(0.9),
                          levelRangeColors[index].withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.grey[300],
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: levelRangeColors[index].withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  levelRanges[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelIconsGrid({bool isHostLevel = false}) {
    // Show all levels when selectedLevelRange is -1
    if (selectedLevelRange == -1) {
      return GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20.h,
          crossAxisSpacing: 20.w,
          childAspectRatio: 0.8,
        ),
        itemCount: levelRangeAssets.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showLevelDetails(index, isHostLevel),
            child: _buildLevelIcon(
              icon: levelRangeAssets[index],
              label: levelRanges[index].replaceAll('Level ', 'Lv '),
              color: levelRangeColors[index],
            ),
          );
        },
      );
    }

    // Show specific range levels
    int startLevel = (selectedLevelRange * 5) + 1;
    int endLevel = (selectedLevelRange + 1) * 5;

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 30.h,
        crossAxisSpacing: 40.w,
        childAspectRatio: 0.8,
      ),
      itemCount: 1, // Show selected range icon
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showLevelDetails(selectedLevelRange, isHostLevel),
          child: _buildLevelIcon(
            icon: levelRangeAssets[selectedLevelRange],
            label: 'Lv ${startLevel}-${endLevel}',
            color: levelRangeColors[selectedLevelRange],
          ),
        );
      },
    );
  }

  void _showLevelDetails(int rangeIndex, bool isHostLevel) {
    final startLevel = (rangeIndex * 5) + 1;
    final endLevel = (rangeIndex + 1) * 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $startLevel-$endLevel Details',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24.sp),
                  ),
                ],
              ),
            ),

            // Level details list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: 5,
                itemBuilder: (context, index) {
                  final level = startLevel + index;
                  final value = isHostLevel
                      ? hostLevelReceiveValues[level] ?? "0"
                      : levelRechargeValues[level] ?? "0";

                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level $level',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
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

  Widget _buildLevelIcon({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80.w,
            height: 80.w,
            child: Image.asset(icon, fit: BoxFit.contain),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelRules() {
    final isHostTab = _tabController.index == 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelRulesPage(isHostLevel: isHostTab),
      ),
    );
  }
}

// Level Rules Page
class LevelRulesPage extends StatelessWidget {
  final bool isHostLevel;

  const LevelRulesPage({super.key, this.isHostLevel = false});

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

  final Map<int, String> hostLevelReceiveValues = const {
    1: "3 lakh",
    2: "9 lakh",
    3: "15 lakh",
    4: "30 lakh",
    5: "45 lakh",
    6: "63 lakh",
    7: "90 lakh",
    8: "126 lakh",
    9: "165 lakh",
    10: "210 lakh",
    11: "300 lakh",
    12: "450 lakh",
    13: "750 lakh",
    14: "1500 lakh",
    15: "3000 lakh",
    16: "6000 lakh",
    17: "12000 lakh",
    18: "24000 lakh",
    19: "45000 lakh",
    20: "90000 lakh",
    21: "150000 lakh",
    22: "30,0000 lakh",
    23: "60,0000 lakh",
    24: "120,0000 lakh",
    25: "240,0000 lakh",
    26: "45,00000 lakh",
    27: "75,00000 lakh",
    28: "120,00000 lakh",
    29: "210,00000 lakh",
    30: "750,00000 lakh",
    31: "600,00000 lakh",
    32: "750,00000 lakh",
    33: "900,00000 lakh",
    34: "150,00000 lakh",
    35: "1200,00000 lakh",
    36: "2100,00000 lakh",
    37: "3600,00000 lakh",
    38: "6600,00000 lakh",
    39: "13200,00000 lakh",
    40: "30000,00000 lakh",
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
          isHostLevel ? 'Host Rules' : 'Level Rules',
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
                        isHostLevel ? 'Receive Coin' : 'Recharge Value',
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
                itemCount: isHostLevel
                    ? hostLevelReceiveValues.length
                    : levelRechargeValues.length,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final value = isHostLevel
                      ? hostLevelReceiveValues[level]!
                      : levelRechargeValues[level]!;
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
