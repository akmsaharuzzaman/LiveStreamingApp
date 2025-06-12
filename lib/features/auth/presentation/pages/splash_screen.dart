import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final List<String> images = [
    'assets/images/splash/slider1.jpg',
    'assets/images/splash/slider2.jpg',
    'assets/images/splash/slider1.jpg'
  ];
  int _countdown = 5;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startSlideshow();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer.cancel();
          _navigateToNextPage();
        }
      });
    });
  }

  void _startSlideshow() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (_currentIndex < images.length - 1 && _countdown > 0) {
        setState(() {
          _currentIndex++;
          _pageController.animateToPage(
            _currentIndex,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  void _navigateToNextPage() {
    context.go('/welcome-screen');
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Image.asset(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),
          Positioned(
            top: 40.sp,
            right: 22.sp,
            child: Container(
              padding: EdgeInsets.only(
                  top: 6.sp, right: 17.sp, left: 17.sp, bottom: 6.sp),
              decoration: BoxDecoration(
                color: Colors.black54.withOpacity(0.3.sp),
                borderRadius: BorderRadius.circular(8.sp),
              ),
              child: Text(
                'Skip $_countdown',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
