import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

void showWebGameBottomSheet(
  BuildContext context, {
  required String gameUrl,
  required String gameTitle,
  String? userId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: false,
    builder: (context) {
      return WebGameBottomSheet(
        gameUrl: gameUrl,
        gameTitle: gameTitle,
        userId: userId,
      );
    },
  );
}

class WebGameBottomSheet extends StatefulWidget {
  final String gameUrl;
  final String gameTitle;
  final String? userId;

  const WebGameBottomSheet({
    super.key,
    required this.gameUrl,
    required this.gameTitle,
    this.userId,
  });

  @override
  State<WebGameBottomSheet> createState() => _WebGameBottomSheetState();
}

class _WebGameBottomSheetState extends State<WebGameBottomSheet> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Build the complete game URL with user parameters
    String completeUrl = widget.gameUrl;
    if (widget.userId != null) {
      // Replace or add user_id parameter
      if (completeUrl.contains('user_id=')) {
        completeUrl = completeUrl.replaceAll(
          RegExp(r'user_id=[^&]*'),
          'user_id=${widget.userId}',
        );
      } else {
        final separator = completeUrl.contains('?') ? '&' : '?';
        completeUrl += '${separator}user_id=${widget.userId}';
      }
    }
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(false)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
            debugPrint('Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(completeUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Header with title and close button
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                // Game title
                Expanded(
                  child: Text(
                    widget.gameTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Refresh button
                GestureDetector(
                  onTap: () {
                    _webViewController.reload();
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                // Close button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.close, color: Colors.red, size: 20.sp),
                  ),
                ),
              ],
            ),
          ),

          // WebView content
          Expanded(
            child: Container(
              margin: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(19.r),
                  bottomRight: Radius.circular(19.r),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(19.r),
                  bottomRight: Radius.circular(19.r),
                ),
                child: Stack(
                  children: [
                    // WebView
                    if (!_hasError)
                      WebViewWidget(controller: _webViewController),

                    // Error state
                    if (_hasError) _buildErrorWidget(),

                    // Loading indicator
                    if (_isLoading && !_hasError) _buildLoadingWidget(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFE91E63),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading ${widget.gameTitle}...',
              style: TextStyle(
                color: const Color(0xFF1A1A2E),
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64.sp),
              SizedBox(height: 16.h),
              Text(
                'Failed to load game',
                style: TextStyle(
                  color: const Color(0xFF1A1A2E),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  _initializeWebView();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
