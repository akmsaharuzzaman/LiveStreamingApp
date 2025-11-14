import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dlstarlive/core/network/api_clients.dart';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/injection/injection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:dlstarlive/features/live_audio/presentation/widgets/optimized_gift_widget.dart';

void showAudioGiftBottomSheet(
  BuildContext context, {
  required List<AudioMember> activeViewers,
  required String roomId,
  String? hostUserId,
  String? hostName,
  String? hostAvatar,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (bottomSheetContext) {
      return GiftBottomSheet(
        activeViewers: activeViewers,
        roomId: roomId,
        hostUserId: hostUserId,
        hostName: hostName,
        hostAvatar: hostAvatar,
      );
    },
  );
}

class GiftBottomSheet extends StatefulWidget {
  final List<AudioMember> activeViewers;
  final String roomId;
  final String? hostUserId;
  final String? hostName;
  final String? hostAvatar;

  const GiftBottomSheet({
    super.key,
    required this.activeViewers,
    required this.roomId,
    this.hostUserId,
    this.hostName,
    this.hostAvatar,
  });

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet>
    with TickerProviderStateMixin {
  TabController? _tabController;
  // --- CORRECTED STATE ---
  // Store the ID of the selected gift instead of its index.
  String? _selectedGiftId;
  int _giftQuantity = 1;
  int _currentBalance = 0; // Will be loaded from API
  Set<String> _selectedUserIds = {}; // Changed to Set for multiple selection
  bool _isLoading = true;
  bool _isSending = false;
  bool _isClosing = false; // ✅ Flag to prevent double dismiss
  List<Gift> _allGifts = [];
  List<Gift> _hotGifts = []; // Hot/popular gifts based on send count
  List<String> _dynamicTabs = []; // Will be populated with categories from API

  // Optimization state for SVGA preloading
  Set<String> _preloadedAnimations =
      {}; // Track which SVGA animations are preloaded

  final GiftApiClient _giftApiClient = getIt<GiftApiClient>();
  final UserApiClient _userApiClient = getIt<UserApiClient>();

  @override
  void initState() {
    super.initState();
    // Don't initialize TabController yet, will be created after loading gifts
    _loadGifts();
    _loadHotGifts(); // Load hot/popular gifts
    _loadUserBalance();
  }

  Future<void> _loadUserBalance() async {
    try {
      // Get current user from AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        setState(() {
          _currentBalance = authState.user.stats?.coins ?? 0;
        });
      } else {
        // Fallback to API call if not available from AuthBloc
        final response = await _userApiClient.getUserProfile();
        if (response.isSuccess && response.data != null) {
          final userData = response.data!;
          setState(() {
            _currentBalance = userData['coins'] ?? userData['balance'] ?? 0;
          });
        }
      }
    } catch (e) {
      _showError('Error loading balance: $e');
    }
  }

  Future<void> _loadGifts() async {
    try {
      final response = await _giftApiClient.getAllGifts();
      if (response.isSuccess && response.data != null) {
        final gifts = response.data!;

        // Extract unique categories from gifts, filtering out null/empty values
        final categories = gifts
            .map((gift) => gift.category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList();
        categories.sort(); // Sort alphabetically

        // Create dynamic tabs: Add "Hot" as first tab, then sorted categories
        final newTabs = ['Hot', ...categories];

        setState(() {
          _allGifts = gifts;
          _dynamicTabs = newTabs;
          _isLoading = false;
        });

        // Create TabController with new length (dispose old one if exists)
        if (_dynamicTabs.isNotEmpty) {
          // Dispose old controller if it exists
          _tabController?.dispose();

          _tabController = TabController(
            length: _dynamicTabs.length,
            vsync: this,
          );
          _tabController!.addListener(() {
            if (!_tabController!.indexIsChanging) {
              // Reset selection when tab changes
              setState(() {
                _selectedGiftId = null;
              });
            }
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Failed to load gifts: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error loading gifts: $e');
    }
  }

  Future<void> _loadHotGifts() async {
    try {
      final response = await _giftApiClient.getAllGifts(
        sortBy: 'sendCount',
        sortOrder: 'desc',
      );
      if (response.isSuccess && response.data != null) {
        setState(() {
          _hotGifts = response.data!;
        });

        // Preload animations for the first 3 hot gifts for better UX
        _preloadTopGiftsAnimations();
      }
    } catch (e) {
      print('Error loading hot gifts: $e');
      // Don't show error to user for hot gifts failure - just fail silently
    }
  }

  /// Preload animations for top 3 hot gifts for better initial UX
  Future<void> _preloadTopGiftsAnimations() async {
    if (_hotGifts.isNotEmpty) {
      // Preload first 3 hot gifts in background
      final topGifts = _hotGifts.take(3);
      for (final gift in topGifts) {
        _preloadGiftAnimation(gift.id);
      }
      debugPrint('🚀 Preloading animations for ${topGifts.length} top gifts');
    }
  }

  /// Preload SVGA animation for a specific gift
  Future<void> _preloadGiftAnimation(String giftId) async {
    if (_preloadedAnimations.contains(giftId)) {
      return; // Already preloaded
    }

    try {
      // Find the gift
      Gift? gift;
      try {
        gift = _allGifts.firstWhere((g) => g.id == giftId);
      } catch (e) {
        gift = _hotGifts.firstWhere((g) => g.id == giftId);
      }

      if (gift.svgaImage.isNotEmpty) {
        // Mark as preloaded immediately to prevent duplicate loading
        setState(() {
          _preloadedAnimations.add(giftId);
        });

        debugPrint('🎬 Preloaded SVGA animation for gift: ${gift.name}');
      }
    } catch (e) {
      debugPrint('❌ Failed to preload animation for gift $giftId: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showWarning(String message) {
    if (!mounted) return;
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void dispose() {
    // Clear preloaded animations set
    _preloadedAnimations.clear();

    // Only dispose if TabController was initialized
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // User avatars and close button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // User avatars
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Host avatar (if available)
                        if (widget.hostUserId != null) ...[
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_selectedUserIds.contains(
                                  widget.hostUserId!,
                                )) {
                                  _selectedUserIds.remove(widget.hostUserId!);
                                } else {
                                  _selectedUserIds.add(widget.hostUserId!);
                                }
                              });
                            },
                            child: _buildUserAvatar(
                              _selectedUserIds.contains(widget.hostUserId!),
                              widget.hostAvatar ??
                                  'https://thispersondoesnotexist.com/',
                              widget.hostName ?? 'Host',
                              true, // isHost
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],

                        // Active viewers
                        ...widget.activeViewers.map((viewer) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedUserIds.contains(viewer.id)) {
                                    _selectedUserIds.remove(viewer.id);
                                  } else {
                                    _selectedUserIds.add(viewer.id ?? '');
                                  }
                                });
                              },
                              child: _buildUserAvatar(
                                _selectedUserIds.contains(viewer.id ?? ''),
                                viewer.avatar ??
                                    'https://thispersondoesnotexist.com/',
                                viewer.name,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // "Select All" option - improved styling
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Check if all users are selected
                      Set<String> allUserIds = {};
                      if (widget.hostUserId != null) {
                        allUserIds.add(widget.hostUserId!);
                      }
                      allUserIds.addAll(
                        widget.activeViewers.map((v) => v.id ?? ''),
                      );

                      if (_selectedUserIds.length == allUserIds.length &&
                          allUserIds.every(
                            (id) => _selectedUserIds.contains(id),
                          )) {
                        // All are selected, deselect all
                        _selectedUserIds.clear();
                      } else {
                        // Not all are selected, select all
                        _selectedUserIds = allUserIds;
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: () {
                        Set<String> allUserIds = {};
                        if (widget.hostUserId != null) {
                          allUserIds.add(widget.hostUserId!);
                        }
                        allUserIds.addAll(
                          widget.activeViewers.map((v) => v.id ?? ''),
                        );
                        bool allSelected =
                            _selectedUserIds.length == allUserIds.length &&
                            allUserIds.every(
                              (id) => _selectedUserIds.contains(id),
                            );
                        return allSelected
                            ? const Color(0xFFE91E63)
                            : const Color(0xFF2A2A3E);
                      }(),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: () {
                          Set<String> allUserIds = {};
                          if (widget.hostUserId != null) {
                            allUserIds.add(widget.hostUserId!);
                          }
                          allUserIds.addAll(
                            widget.activeViewers.map((v) => v.id ?? ''),
                          );
                          bool allSelected =
                              _selectedUserIds.length == allUserIds.length &&
                              allUserIds.every(
                                (id) => _selectedUserIds.contains(id),
                              );
                          return allSelected
                              ? const Color(0xFFE91E63)
                              : Colors.white24;
                        }(),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Select All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          () {
                            Set<String> allUserIds = {};
                            if (widget.hostUserId != null) {
                              allUserIds.add(widget.hostUserId!);
                            }
                            allUserIds.addAll(
                              widget.activeViewers.map((v) => v.id ?? ''),
                            );
                            bool allSelected =
                                _selectedUserIds.length == allUserIds.length &&
                                allUserIds.every(
                                  (id) => _selectedUserIds.contains(id),
                                );
                            return allSelected
                                ? Icons.check_circle
                                : Icons.check_circle_outline;
                          }(),
                          color: () {
                            Set<String> allUserIds = {};
                            if (widget.hostUserId != null) {
                              allUserIds.add(widget.hostUserId!);
                            }
                            allUserIds.addAll(
                              widget.activeViewers.map((v) => v.id ?? ''),
                            );
                            bool allSelected =
                                _selectedUserIds.length == allUserIds.length &&
                                allUserIds.every(
                                  (id) => _selectedUserIds.contains(id),
                                );
                            return allSelected ? Colors.white : Colors.white54;
                          }(),
                          size: 16.sp,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // Close button
                GestureDetector(
                  onTap: () {
                    if (!_isClosing && !_isSending) {
                      _closeBottomSheet();
                    }
                  },
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 20.sp),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // Tabs - only show when data is loaded
          if (!_isLoading && _dynamicTabs.isNotEmpty && _tabController != null)
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              child: TabBar(
                controller: _tabController!,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFFE91E63),
                indicatorWeight: .1,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFFE91E63),
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
                tabs: _dynamicTabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),

          // Gift grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                  )
                : _dynamicTabs.isEmpty || _tabController == null
                ? const Center(
                    child: Text(
                      'No gift categories available',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : TabBarView(
                    controller: _tabController!,
                    children: _dynamicTabs.map((category) {
                      if (category == 'Hot') {
                        // Show hot/popular gifts for "Hot" tab
                        return _buildGiftGrid(_hotGifts, category);
                      } else {
                        // Filter by exact category match for other tabs
                        final categoryGifts = _allGifts
                            .where(
                              (gift) =>
                                  gift.category.toLowerCase() ==
                                  category.toLowerCase(),
                            )
                            .toList();
                        return _buildGiftGrid(categoryGifts, category);
                      }
                    }).toList(),
                  ),
          ),

          // Bottom section with quantity dropdown and send button
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              // color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                // Quantity selector (Dropdown) - matching design
                Container(
                  width: 120.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF424040),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Stack(
                    children: [
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: DropdownButton<int>(
                            value: _giftQuantity,
                            icon: const SizedBox.shrink(), // Hide default icon
                            dropdownColor: const Color(0xFF424040),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _giftQuantity = val);
                              }
                            },
                            items: const [1, 2, 3, 4, 5, 10, 20, 50, 100]
                                .map(
                                  (q) => DropdownMenuItem<int>(
                                    value: q,
                                    child: Text('$q'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      // Custom triangle arrow pointing up
                      Positioned(
                        right: 12.w,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white70,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16.w),

                // Balance display - improved styling
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.h,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 12.sp,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '$_currentBalance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Send button
                GestureDetector(
                  // --- CORRECTED CONDITION ---
                  onTap:
                      (_selectedGiftId != null &&
                          _selectedUserIds.isNotEmpty &&
                          !_isSending)
                      ? _sendGift
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          (_selectedGiftId != null &&
                              _selectedUserIds.isNotEmpty &&
                              !_isSending)
                          ? const LinearGradient(
                              colors: [Color(0xFF825CB3), Color(0xFF984E64)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color:
                          (_selectedGiftId == null ||
                              _selectedUserIds.isEmpty ||
                              _isSending)
                          ? Colors.grey[600]
                          : null,
                      borderRadius: BorderRadius.circular(25.r),
                      // boxShadow:
                      //     (_selectedGiftId != null &&
                      //         _selectedUserIds.isNotEmpty &&
                      //         !_isSending)
                      //     ? [
                      //         BoxShadow(
                      //           color: const Color(0xFFE91E63).withValues(alpha:0.3),
                      //           blurRadius: 8,
                      //           offset: const Offset(0, 4),
                      //         ),
                      //       ]
                      //     : null,
                    ),
                    child: _isSending
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Send',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(
    bool isSelected,
    String imageUrl, [
    String? name,
    bool isHost = false,
  ]) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: const Color(0xFFFFFFFF), width: 3)
                : Border.all(color: Colors.white24, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[600],
                  child: Icon(Icons.person, color: Colors.white, size: 35.sp),
                );
              },
            ),
          ),
        ),
        // if (name != null) ...[
        //   SizedBox(height: 4.h),
        //   Text(
        //     isHost ? '👑 $name' : name,
        //     style: TextStyle(
        //       color: isSelected ? Colors.white : Colors.white70,
        //       fontSize: 10.sp,
        //       fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        //     ),
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        // ],
      ],
    );
  }

  Widget _buildGiftGrid(List<Gift> gifts, [String? category]) {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.8,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        // --- CORRECTED LOGIC ---
        // Check for selection using the gift's unique ID.
        final isSelected = _selectedGiftId == gift.id;

        return AudioOptimizedGiftWidget(
          gift: gift,
          isSelected: isSelected,
          preloadedAnimations: _preloadedAnimations,
          onAnimationPreload: _preloadGiftAnimation,
          onTap: () {
            // --- CORRECTED LOGIC ---
            // Store the gift's unique ID on tap.
            setState(() {
              _selectedGiftId = gift.id;
            });
          },
        );
      },
    );
  }

  Future<void> _sendGift() async {
    if (_selectedGiftId == null) {
      _showWarning('Please select a gift first!');
      return;
    }

    if (_selectedUserIds.isEmpty) {
      _showWarning('Please select at least one recipient!');
      return;
    }

    // --- CORRECTED LOGIC ---
    // Find the selected gift from all available gifts (both hot and regular)
    Gift? selectedGift;
    try {
      selectedGift = _allGifts.firstWhere((g) => g.id == _selectedGiftId);
    } catch (e) {
      try {
        selectedGift = _hotGifts.firstWhere((g) => g.id == _selectedGiftId);
      } catch (e) {
        _showError('Selected gift not found!');
        return;
      }
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Prepare recipient information
      List<String> recipientIds = _selectedUserIds.toList();
      int recipientCount = recipientIds.length;

      // Calculate total cost based on recipients and quantity
      final totalCost = selectedGift.coinPrice * _giftQuantity * recipientCount;

      if (totalCost > _currentBalance) {
        setState(() => _isSending = false);
        _showError('Insufficient balance!');
        return;
      }

      // Send gift using new API with multiple recipients and quantity
      final response = await _giftApiClient.sendGift(
        userIds: recipientIds,
        roomId: widget.roomId,
        giftId: selectedGift.id,
        qty: _giftQuantity,
      );

      if (response.isSuccess) {
        setState(() {
          _currentBalance -= totalCost;
        });

        // Show success message
        _showSuccess(
          'Gift sent successfully to $recipientCount recipient${recipientCount > 1 ? 's' : ''}!',
        );

        // Reset selection
        setState(() {
          // --- CORRECTED RESET ---
          _selectedGiftId = null;
          _giftQuantity = 1;
          _selectedUserIds.clear(); // Clear all selected users
          _isSending = false;
        });

        // Close bottom sheet after a delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && !_isClosing) {
            _closeBottomSheet();
          }
        });
      } else {
        setState(() => _isSending = false);
        _showError('Failed to send gift: ${response.message}');
      }
    } catch (e) {
      setState(() => _isSending = false);
      _showError('Error sending gift: $e');
    }
  }

  /// ✅ Helper method to close bottom sheet safely and prevent double dismiss
  void _closeBottomSheet() {
    if (!_isClosing && mounted) {
      setState(() {
        _isClosing = true;
      });
      Navigator.pop(context);
    }
  }
}
