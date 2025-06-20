import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class MyTabBar extends StatefulWidget {
  const MyTabBar({super.key, required this.tabController});

  final TabController tabController;

  @override
  State<MyTabBar> createState() => _MyTabBarState();
}

class _MyTabBarState extends State<MyTabBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: IntrinsicHeight(
        child: TabBar(
          controller: widget.tabController,
          indicator: const BoxDecoration(),
          dividerColor: Colors.transparent,
          dividerHeight: 1,
          tabs: [
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: widget.tabController,
                        builder: (context, child) {
                          return widget.tabController.index == 0
                              ? Container(
                                  width: 25,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : const SizedBox();
                        },
                      ),
                      Icon(Iconsax.message, size: 20.sp),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text('Chat', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: widget.tabController,
                        builder: (context, child) {
                          return widget.tabController.index == 1
                              ? Container(
                                  width: 25,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : const SizedBox();
                        },
                      ),
                      Icon(Iconsax.status, size: 20.sp),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text('Status', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: widget.tabController,
                        builder: (context, child) {
                          return widget.tabController.index == 2
                              ? Container(
                                  width: 25,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : const SizedBox();
                        },
                      ),
                      Icon(Iconsax.call, size: 20.sp),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text('Calls', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
