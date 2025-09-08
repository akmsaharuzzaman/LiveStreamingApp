import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/models/agency_models.dart';

enum AgencyPageState { loading, list, member, pending, congrats, error }

class MyAgencyPage extends StatefulWidget {
  final UserModel user;

  const MyAgencyPage({super.key, required this.user});

  @override
  State<MyAgencyPage> createState() => _MyAgencyPageState();
}

class _MyAgencyPageState extends State<MyAgencyPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService.instance;

  AgencyPageState _pageState = AgencyPageState.loading;
  List<Agency> _agencies = [];
  AgencyDetails? _currentAgencyDetails;
  String? _errorMessage;
  bool _isProcessing = false;

  // Pagination
  int _currentPage = 1;
  bool _hasMoreData = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _checkAgencyStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Check current user's agency status
  Future<void> _checkAgencyStatus() async {
    setState(() {
      _pageState = AgencyPageState.loading;
    });

    final result = await _apiService.getAgencyStatus();

    result.when(
      success: (response) {
        if (response.success) {
          switch (response.result.status) {
            case 'list':
              setState(() {
                _pageState = AgencyPageState.member;
              });
              _loadAgencyList();
              break;
            case 'member':
              setState(() {
                _pageState = AgencyPageState.member;
                _currentAgencyDetails = response.result.agencyDetails;
              });
              break;
            case 'pending':
              setState(() {
                _pageState = AgencyPageState.pending;
                _currentAgencyDetails = response.result.agencyDetails;
              });
              break;
            case 'congrats':
              setState(() {
                _pageState = AgencyPageState.congrats;
                _currentAgencyDetails = response.result.agencyDetails;
              });
              break;
          }
        } else {
          setState(() {
            _pageState = AgencyPageState.error;
            _errorMessage = 'Failed to get agency status';
          });
        }
      },
      failure: (error) {
        setState(() {
          _pageState = AgencyPageState.error;
          _errorMessage = error;
        });
      },
    );
  }

  /// Load agency list when status is 'list'
  Future<void> _loadAgencyList({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _agencies.clear();
    }

    final result = await _apiService.getAgencyList(
      page: _currentPage,
      limit: 10,
    );

    result.when(
      success: (response) {
        if (response.success) {
          setState(() {
            if (refresh) {
              _agencies = response.result.data;
            } else {
              _agencies.addAll(response.result.data);
            }
            _hasMoreData =
                response.result.pagination.page <
                response.result.pagination.totalPage;
            _currentPage++;
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
            _pageState = AgencyPageState.error;
          });
        }
      },
      failure: (error) {
        setState(() {
          _errorMessage = error;
          _pageState = AgencyPageState.error;
          _isLoadingMore = false;
        });
      },
    );
  }

  /// Join an agency
  Future<void> _joinAgency(String agencyId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final result = await _apiService.joinAgency(agencyId);

    result.when(
      success: (response) {
        if (response.success) {
          _showSnackBar('Join request sent successfully!', Colors.green);
          // Refresh status to check new state
          _checkAgencyStatus();
        } else {
          _showSnackBar(
            response.message ?? 'Failed to join agency',
            Colors.red,
          );
        }
        setState(() {
          _isProcessing = false;
        });
      },
      failure: (error) {
        _showSnackBar(error, Colors.red);
        setState(() {
          _isProcessing = false;
        });
      },
    );
  }

  /// Cancel agency join request
  Future<void> _cancelAgencyRequest() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final result = await _apiService.cancelAgencyRequest();

    result.when(
      success: (response) {
        if (response.success) {
          _showSnackBar('Request cancelled successfully!', Colors.green);
          // Refresh status to check new state
          _checkAgencyStatus();
        } else {
          _showSnackBar(
            response.message ?? 'Failed to cancel request',
            Colors.red,
          );
        }
        setState(() {
          _isProcessing = false;
        });
      },
      failure: (error) {
        _showSnackBar(error, Colors.red);
        setState(() {
          _isProcessing = false;
        });
      },
    );
  }

  /// Show congratulations and move to member status
  void _handleCongratsAcknowledge() {
    setState(() {
      _pageState = AgencyPageState.member;
    });
  }

  /// Show snackbar message
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
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
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_pageState) {
      case AgencyPageState.loading:
        return _buildLoadingState();
      case AgencyPageState.list:
        return _buildAgencyListState();
      case AgencyPageState.member:
        return _buildMemberState();
      case AgencyPageState.pending:
        return _buildPendingState();
      case AgencyPageState.congrats:
        return _buildCongratsState();
      case AgencyPageState.error:
        return _buildErrorState();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading agency information...'),
        ],
      ),
    );
  }

  Widget _buildAgencyListState() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Search Section
          _buildSearchSection(),
          SizedBox(height: 20.h),

          // Agency List
          Expanded(
            child: _agencies.isEmpty
                ? const Center(child: Text('No agencies found'))
                : RefreshIndicator(
                    onRefresh: () => _loadAgencyList(refresh: true),
                    child: ListView.builder(
                      itemCount: _agencies.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _agencies.length) {
                          // Load more indicator
                          if (!_isLoadingMore && _hasMoreData) {
                            Future.microtask(() => _loadAgencyList());
                          }
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildAgencyCard(_agencies[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberState() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7D299D), // Purple
              Color(0xFF7D299D), // Darker purple
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
                      width: 390.w,
                      height: 222.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Image.asset(
                        "assets/images/general/welcome_banner.png",
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
                      child: Image.asset(
                        "assets/images/general/welcome_icon.png",
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF082A7B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                          ),
                          child: Text(
                            'Continue',
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

  Widget _buildPendingState() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pending_actions, size: 80.sp, color: Colors.orange),
          SizedBox(height: 20.h),
          Text(
            'Request Pending',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Your request to join',
            style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 5.h),
          Text(
            _currentAgencyDetails?.name ?? 'Unknown Agency',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'is under review',
            style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 40.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _cancelAgencyRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Cancel Request',
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
          SizedBox(height: 20.h),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Go Back',
              style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCongratsState() {
    return CongratulationsPage(
      agencyName: _currentAgencyDetails?.name ?? 'Unknown Agency',
      onContinue: () => _showWelcomePage(),
    );
  }

  void _showWelcomePage() {
    setState(() {
      _pageState = AgencyPageState
          .member; // Change to member state after congratulations
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CongratePage(
          agencyName: _currentAgencyDetails?.name ?? 'Unknown Agency',
          onFinish: () {
            Navigator.of(context).pop(); // Go back to the main agency page
            _checkAgencyStatus(); // Refresh the status
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80.sp, color: Colors.red),
          SizedBox(height: 20.h),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: _checkAgencyStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF082A7B),
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              fillColor: const Color(0xFFF5F5F5),
              filled: true,
              hintText: 'Search agency ID',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: const Color(0xFF888686),
                  width: 1.w,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: const Color(0xFF888686),
                  width: 1.w,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: const Color(0xFF888686),
                  width: 1.w,
                ),
              ),
              contentPadding: EdgeInsets.all(16.w),
            ),
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
        ),
        SizedBox(width: 10.w),
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFF888686)),
          ),
          child: Icon(Icons.search, color: Colors.grey[600], size: 24.sp),
        ),
      ],
    );
  }

  Widget _buildAgencyCard(Agency agency) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAA2), // Yellow background like in old version
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
            child: Icon(Icons.business, color: Colors.white, size: 30.sp),
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
                  'ID: ${agency.userId}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Join Button
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _joinAgency(agency.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF082A7B), // Blue color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 16.h,
                    width: 16.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Join',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Congratulations Page
class CongratulationsPage extends StatelessWidget {
  final String agencyName;
  final VoidCallback onContinue;

  const CongratulationsPage({
    super.key,
    required this.agencyName,
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
              Color(0xFF7D299D), // Purple
              Color(0xFF7D299D), // Darker purple
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
                    SizedBox(
                      width: 100.w,
                      height: 100.w,
                      child: Image.asset(
                        "assets/images/general/congratulation_icon.png",
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
class CongratePage extends StatelessWidget {
  final String agencyName;
  final VoidCallback onFinish;

  const CongratePage({
    super.key,
    required this.agencyName,
    required this.onFinish,
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
              Color(0xFF7D299D), // Purple
              Color(0xFF7D299D), // Darker purple
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
                    SizedBox(
                      width: 100.w,
                      height: 100.w,
                      child: Image.asset(
                        "assets/images/general/congratulation_icon.png",
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
                              onPressed: () {},
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
