import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  int selectedCoins = 100;

  final List<int> coinAmounts = [100, 500, 1000, 2000, 5000, 10000];

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

              // Coin Display
              _buildCoinDisplay(),

              // Payment Methods Section
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 50.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 30.h),

                      // Payment Methods
                      _buildPaymentMethods(),

                      SizedBox(height: 30.h),

                      // Top up for friend button
                      _buildTopUpForFriendButton(),

                      SizedBox(height: 20.h),
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
            'Top-up',
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

  Widget _buildCoinDisplay() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // Coin icon and amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700), // Gold color
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 15.w),
              Text(
                selectedCoins.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Coin amount selector (if needed)
          // You can add coin selection buttons here if required
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            _buildPaymentMethodItem(
              icon: 'assets/icons/marchent_icon.png',
              title: 'Official Merchant',
              onTap: () => _navigateToOfficialMerchant(),
            ),
            SizedBox(height: 15.h),

            _buildPaymentMethodItem(
              icon: 'assets/icons/bkash_icon.png',
              title: 'Bkash',
              onTap: () => _handleBkashPayment(),
            ),
            SizedBox(height: 15.h),

            _buildPaymentMethodItem(
              icon: 'assets/icons/nagad_icon.png',
              title: 'Nagad',
              onTap: () => _handleNagadPayment(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Image.asset(
                icon,
                width: 40.w,
                height: 40.w,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUpForFriendButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: () => _handleTopUpForFriend(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Top up for friend',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 10.w),
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToOfficialMerchant() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OfficialMerchantPage()),
    );
  }

  void _handleStripePayment() {
    // Handle Stripe payment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stripe payment coming soon!')),
    );
  }

  void _handleBkashPayment() {
    // Handle Bkash payment
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bkash payment coming soon!')));
  }

  void _handleNagadPayment() {
    // Handle Nagad payment
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nagad payment coming soon!')));
  }

  void _handleTopUpForFriend() {
    // Handle top up for friend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Top up for friend coming soon!')),
    );
  }
}

// Official Merchant Page
class OfficialMerchantPage extends StatelessWidget {
  const OfficialMerchantPage({super.key});

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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                      'Official Merchant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Service Badge
              Container(
                margin: EdgeInsets.symmetric(vertical: 30.h),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Official Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Merchant List
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(20.w),
                    children: [
                      _buildMerchantItem(
                        name: 'Habib Khan',
                        country: 'Official',
                        flag: '🇫🇷', // French flag
                        context: context,
                      ),
                      _buildMerchantItem(
                        name: 'Habib Khan',
                        country: 'Official',
                        flag: '🇵🇹', // Portuguese flag
                        context: context,
                      ),
                      _buildMerchantItem(
                        name: 'Habib Khan',
                        country: 'Official',
                        flag: '', // No flag
                        context: context,
                      ),
                      _buildMerchantItem(
                        name: 'Habib Khan',
                        country: 'Official',
                        flag: '🇧🇩', // Bangladesh flag
                        context: context,
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

  Widget _buildMerchantItem({
    required String name,
    required String country,
    required String flag,
    required BuildContext context,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.r),
              color: Colors.grey.shade300,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25.r),
              child: Image.asset(
                'assets/images/general/profile_icon.png', // Using profile icon
                width: 50.w,
                height: 50.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.person,
                      size: 30.sp,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 15.w),

          // Name and Country
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    if (flag.isNotEmpty) ...[
                      Text(flag, style: TextStyle(fontSize: 16.sp)),
                      SizedBox(width: 5.w),
                    ],
                    Text(
                      country,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // WhatsApp Button
          GestureDetector(
            onTap: () {
              // Handle WhatsApp contact
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening WhatsApp...')),
              );
            },
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366), // WhatsApp green
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Icon(Icons.chat, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}
