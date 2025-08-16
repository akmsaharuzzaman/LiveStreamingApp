import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dlstarlive/core/network/api_clients.dart';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/core/network/models/joined_user_model.dart';
import 'package:dlstarlive/injection/injection.dart';

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
  int _selectedGiftIndex = -1;
  int _giftQuantity = 1;
  int _currentBalance = 150000;
  String? _selectedUserId; // null means send to host
  bool _isLoading = true;
  bool _isSending = false;
  List<Gift> _allGifts = [];
  List<Gift> _currentCategoryGifts =
      []; // Track current category gifts for selection

  final GiftApiClient _giftApiClient = getIt<GiftApiClient>();

  // Categories for gifts
  final List<String> _tabs = ['Recent', 'Hot', 'SVIP', 'Nobel', 'Package'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadGifts();
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
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedUserId == null
                                      ? const Color(0xFFE91E63)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: _buildUserAvatar(
                                widget.hostAvatar ??
                                    'https://thispersondoesnotexist.com/',
                                widget.hostName ?? 'Host',
                                true, // isHost
                              ),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedUserId == viewer.id
                                        ? const Color(0xFFE91E63)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: _buildUserAvatar(
                                  viewer.avatar.isNotEmpty
                                      ? viewer.avatar
                                      : 'https://thispersondoesnotexist.com/',
                                  viewer.name,
                                ),
                              ),
                            ),
                          );
                        }),

                        // "All" option
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserId = 'all';
                            });
                          },
                          child: Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: _selectedUserId == 'all'
                                  ? const Color(0xFFE91E63)
                                  : const Color(0xFF2A2A3E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedUserId == 'all'
                                    ? const Color(0xFFE91E63)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'All',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
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

          // Level progress bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'LV.1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    child: LinearProgressIndicator(
                      value: 0.3,
                      backgroundColor: Colors.grey[600],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'LV.2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Level up text
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'Send this gift to receive 50k level up',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ),

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
                      final categoryGifts = _allGifts
                          .where(
                            (gift) =>
                                gift.category.toLowerCase() ==
                                    category.toLowerCase() ||
                                category == 'Recent',
                          ) // Show all gifts in Recent for now
                          .toList();
                      return _buildGiftGrid(categoryGifts, category);
                    }).toList(),
                  ),
          ),

          // Bottom section with quantity and send button
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
                // Quantity selector
                Container(
                  width: 80.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_giftQuantity > 1) {
                            setState(() {
                              _giftQuantity--;
                            });
                          }
                        },
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      Text(
                        '$_giftQuantity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _giftQuantity++;
                          });
                        },
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16.w),

                // Balance
                Row(
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
                    SizedBox(width: 4.w),
                    Text(
                      '$_currentBalance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Send button
                GestureDetector(
                  onTap: (_selectedGiftIndex >= 0 && !_isSending)
                      ? _sendGift
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: (_selectedGiftIndex >= 0 && !_isSending)
                          ? const Color(0xFFE91E63)
                          : Colors.grey[600],
                      borderRadius: BorderRadius.circular(20.r),
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
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
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        if (name != null) ...[
          SizedBox(height: 4.h),
          Text(
            isHost ? '👑 $name' : name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildGiftGrid(List<Gift> gifts, [String? category]) {
    // Update current category gifts when building grid
    if (category != null) {
      _currentCategoryGifts = gifts;
    }

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
        final isSelected = _selectedGiftIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGiftIndex = index;
              _currentCategoryGifts = gifts; // Update current category gifts
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE91E63).withValues(alpha: 0.2)
                  : const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE91E63)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
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
                      '${gift.coinPrice}',
                      style: TextStyle(color: Colors.white70, fontSize: 10.sp),
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
    if (_selectedGiftIndex >= 0 &&
        _selectedGiftIndex < _currentCategoryGifts.length) {
      setState(() {
        _isSending = true;
      });

      final selectedGift = _currentCategoryGifts[_selectedGiftIndex];
      final totalCost = selectedGift.coinPrice * _giftQuantity;

      if (totalCost <= _currentBalance) {
        try {
          // Determine recipient
          String recipientId;
          String recipientName;

          if (_selectedUserId == null) {
            // Send to host
            if (widget.hostUserId == null) {
              _showError('Host information not available');
              setState(() {
                _isSending = false;
              });
              return;
            }
            recipientId = widget.hostUserId!;
            recipientName = widget.hostName ?? 'Host';
          } else if (_selectedUserId == 'all') {
            // TODO: Implement send to all functionality
            _showError('Send to all functionality not implemented yet');
            setState(() {
              _isSending = false;
            });
            return;
          } else {
            // Send to specific viewer
            try {
              final viewer = widget.activeViewers.firstWhere(
                (v) => v.id == _selectedUserId,
              );
              recipientId = viewer.id;
              recipientName = viewer.name;
            } catch (e) {
              _showError('Selected viewer not found');
              setState(() {
                _isSending = false;
              });
              return;
            }
          }

          // Send gift for each quantity
          bool allSuccessful = true;
          String errorMessage = '';

          for (int i = 0; i < _giftQuantity; i++) {
            print('Sending gift attempt ${i + 1}/$_giftQuantity');
            print('Recipients: userId=$recipientId, roomId=${widget.roomId}, giftId=${selectedGift.id}');
            
            final response = await _giftApiClient.sendGift(
              userId: recipientId,
              roomId: widget.roomId,
              giftId: selectedGift.id,
            );

            print('Gift send response: success=${response.isSuccess}, message=${response.message}');

            if (!response.isSuccess) {
              allSuccessful = false;
              errorMessage = response.message ?? 'Failed to send gift';
              break;
            }
          }

          if (allSuccessful) {
            setState(() {
              _currentBalance -= totalCost;
            });

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sent ${selectedGift.name} x$_giftQuantity to $recipientName!',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFE91E63),
                  duration: const Duration(seconds: 2),
                ),
              );
            }

            // Reset selection
            setState(() {
              _selectedGiftIndex = -1;
              _giftQuantity = 1;
              _selectedUserId = null;
              _isSending = false;
            });

            // Close bottom sheet after a delay
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          } else {
            setState(() {
              _isSending = false;
            });
            _showError('Failed to send gift: $errorMessage');
          }
        } catch (e) {
          setState(() {
            _isSending = false;
          });
          _showError('Error sending gift: $e');
        }
      } else {
        setState(() {
          _isSending = false;
        });
        // Show insufficient balance message
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
      }
    }
  }
}
