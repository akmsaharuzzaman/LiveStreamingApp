import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dlstarlive/core/network/api_clients.dart';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/core/network/models/joined_user_model.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/injection/injection.dart';

import '../../../../core/utils/app_utils.dart';

void showGiftBottomSheet(
  BuildContext context, {
  required List<JoinedUserModel> activeViewers,
  required String roomId,
  String? hostUserId,
  String? hostName,
  String? hostAvatar,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
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
  final List<JoinedUserModel> activeViewers;
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
  late TabController _tabController;
  // --- CORRECTED STATE ---
  // Store the ID of the selected gift instead of its index.
  String? _selectedGiftId;
  int _giftQuantity = 1;
  int _currentBalance = 0; // Will be loaded from API
  String? _selectedUserId; // null means send to host
  bool _isLoading = true;
  bool _isSending = false;
  List<Gift> _allGifts = [];

  final GiftApiClient _giftApiClient = getIt<GiftApiClient>();
  final UserApiClient _userApiClient = getIt<UserApiClient>();

  // Categories for gifts
  final List<String> _tabs = ['Recent', 'Hot', 'SVIP', 'Nobel', 'Package'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Reset selection when tab changes
        setState(() {
          _selectedGiftId = null;
        });
      }
    });
    _loadGifts();
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
        setState(() {
          _allGifts = response.data!;
          _isLoading = false;
        });
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                                _selectedUserId = null; // null means host
                              });
                            },
                            child: _buildUserAvatar(
                              _selectedUserId == null,
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
                                  _selectedUserId = viewer.id;
                                });
                              },
                              child: _buildUserAvatar(
                                _selectedUserId == viewer.id,
                                viewer.avatar.isNotEmpty
                                    ? viewer.avatar
                                    : 'https://thispersondoesnotexist.com/',
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
                      _selectedUserId = 'all';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedUserId == 'all'
                          ? const Color(0xFFE91E63)
                          : const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: _selectedUserId == 'all'
                            ? const Color(0xFFE91E63)
                            : Colors.white24,
                        width: 2,
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
                          _selectedUserId == 'all'
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: _selectedUserId == 'all'
                              ? Colors.white
                              : Colors.white54,
                          size: 16.sp,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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

          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFFE91E63),
              indicatorWeight: 2,
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
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),

          // Gift grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: _tabs.map((category) {
                      List<Gift> categoryGifts;
                      if (category == 'Recent') {
                        // Show all gifts for Recent tab
                        categoryGifts = _allGifts;
                      } else {
                        // Filter by exact category match
                        categoryGifts = _allGifts
                            .where(
                              (gift) =>
                                  gift.category.toLowerCase() ==
                                  category.toLowerCase(),
                            )
                            .toList();
                      }
                      return _buildGiftGrid(categoryGifts, category);
                    }).toList(),
                  ),
          ),

          // Bottom section with quantity dropdown and send button
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
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
                    color: const Color(0xFF1A1A2E),
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
                            dropdownColor: const Color(0xFF2A2A3E),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
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
                ),

                const Spacer(),

                // Send button
                GestureDetector(
                  // --- CORRECTED CONDITION ---
                  onTap: (_selectedGiftId != null && !_isSending)
                      ? _sendGift
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: (_selectedGiftId != null && !_isSending)
                          ? const LinearGradient(
                              colors: [Color(0xFFFF6B9D), Color(0xFFE91E63)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: (_selectedGiftId == null || _isSending)
                          ? Colors.grey[600]
                          : null,
                      borderRadius: BorderRadius.circular(25.r),
                      boxShadow: (_selectedGiftId != null && !_isSending)
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
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
                ? Border.all(color: const Color(0xFFE91E63), width: 3)
                : Border.all(color: Colors.white24, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withOpacity(0.3),
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

        return GestureDetector(
          onTap: () {
            // --- CORRECTED LOGIC ---
            // Store the gift's unique ID on tap.
            setState(() {
              _selectedGiftId = gift.id;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              // color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12.r),
              border: isSelected
                  ? Border.all(color: const Color(0xFFE91E63), width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Use network image for gift preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        gift.previewImage,
                        width: 32.w,
                        height: 32.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 32.w,
                            height: 32.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.card_giftcard,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      gift.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.diamond, color: Colors.blue, size: 10.sp),
                        SizedBox(width: 2.w),
                        Text(
                          AppUtils.formatNumber(gift.coinPrice),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendGift() async {
    if (_selectedGiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gift first!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // --- CORRECTED LOGIC ---
    // Find the selected gift from the main list using its ID.
    final selectedGift = _allGifts.firstWhere((g) => g.id == _selectedGiftId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending gift...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 5),
      ),
    );
    setState(() {
      _isSending = true;
    });

    try {
      // Determine recipients
      List<String> recipientIds = [];
      String successRecipientLabel = '';
      int recipientCount = 1;

      if (_selectedUserId == null) {
        // Host only
        if (widget.hostUserId == null) {
          _showError('Host information not available');
          setState(() => _isSending = false);
          return;
        }
        recipientIds = [widget.hostUserId!];
        successRecipientLabel = widget.hostName ?? 'Host';
      } else if (_selectedUserId == 'all') {
        // Host + all active viewers
        final ids = <String>{};
        if (widget.hostUserId != null) ids.add(widget.hostUserId!);
        ids.addAll(widget.activeViewers.map((v) => v.id));
        recipientIds = ids.toList();
        recipientCount = recipientIds.length;
        successRecipientLabel = 'All ($recipientCount)';
      } else {
        // Specific viewer
        try {
          final viewer = widget.activeViewers.firstWhere(
            (v) => v.id == _selectedUserId,
          );
          recipientIds = [viewer.id];
          successRecipientLabel = viewer.name;
        } catch (e) {
          _showError('Selected viewer not found');
          setState(() => _isSending = false);
          return;
        }
      }

      // Calculate total cost based on recipients
      final totalCost =
          selectedGift.coinPrice * _giftQuantity * recipientIds.length;

      if (totalCost > _currentBalance) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Insufficient balance!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Send gift for each recipient and quantity
      bool allSuccessful = true;
      String errorMessage = '';

      for (final recipientId in recipientIds) {
        for (int i = 0; i < _giftQuantity; i++) {
          final response = await _giftApiClient.sendGift(
            userId: recipientId,
            roomId: widget.roomId,
            giftId: selectedGift.id,
          );
          if (!response.isSuccess) {
            allSuccessful = false;
            errorMessage = response.message ?? 'Failed to send gift';
            break;
          }
        }
        if (!allSuccessful) break;
      }

      if (allSuccessful) {
        setState(() {
          _currentBalance -= totalCost;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sent ${selectedGift.name} x$_giftQuantity to $successRecipientLabel!',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFE91E63),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Reset selection
        setState(() {
          // --- CORRECTED RESET ---
          _selectedGiftId = null;
          _giftQuantity = 1;
          _selectedUserId = null; // Default back to the host
          _isSending = false;
        });

        // Close bottom sheet after a delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        setState(() => _isSending = false);
        _showError('Failed to send gift: $errorMessage');
      }
    } catch (e) {
      setState(() => _isSending = false);
      _showError('Error sending gift: $e');
    }
  }
}
