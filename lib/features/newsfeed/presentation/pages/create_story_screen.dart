import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _mediaFile;
  bool _isVideo = false;
  bool _isLoading = false;
  String _overlayText = '';
  Offset _textPosition = const Offset(0.5, 0.5);
  Color _textColor = Colors.white;
  double _textSize = 24.0;
  FontWeight _textWeight = FontWeight.bold;
  VideoPlayerController? _videoController;
  GlobalKey _repaintBoundaryKey = GlobalKey();

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _videoController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Story',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_mediaFile != null)
            TextButton(
              onPressed: _uploadStory,
              child: Text(
                'Share',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _mediaFile == null ? _buildMediaSelector() : _buildEditor(),
    );
  }

  Widget _buildMediaSelector() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 80.sp, color: Colors.white54),
          SizedBox(height: 24.h),
          Text(
            'Create your story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Share a photo or video',
            style: TextStyle(color: Colors.white70, fontSize: 16.sp),
          ),
          SizedBox(height: 48.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _pickMedia(ImageSource.gallery),
              ),
              _buildMediaButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _pickMedia(ImageSource.camera),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120.w,
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.sp, color: Colors.white),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Stack(
      children: [
        // Media display
        Positioned.fill(
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Stack(
              children: [
                // Background media
                Positioned.fill(
                  child: _isVideo ? _buildVideoPlayer() : _buildImageDisplay(),
                ),
                // Text overlay
                if (_overlayText.isNotEmpty)
                  Positioned(
                    left: _textPosition.dx * MediaQuery.of(context).size.width,
                    top: _textPosition.dy * MediaQuery.of(context).size.height,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _textPosition = Offset(
                            (_textPosition.dx *
                                        MediaQuery.of(context).size.width +
                                    details.delta.dx) /
                                MediaQuery.of(context).size.width,
                            (_textPosition.dy *
                                        MediaQuery.of(context).size.height +
                                    details.delta.dy) /
                                MediaQuery.of(context).size.height,
                          );
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _overlayText,
                          style: TextStyle(
                            color: _textColor,
                            fontSize: _textSize.sp,
                            fontWeight: _textWeight,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                // Media controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.text_fields,
                      label: 'Text',
                      onTap: _showTextEditor,
                    ),
                    if (!_isVideo)
                      _buildControlButton(
                        icon: Icons.crop,
                        label: 'Crop',
                        onTap: _cropImage,
                      ),
                    if (_isVideo)
                      _buildControlButton(
                        icon: Icons.music_note,
                        label: 'Audio',
                        onTap: _showAudioSelector,
                      ),
                    _buildControlButton(
                      icon: Icons.palette,
                      label: 'Filter',
                      onTap: _showFilterOptions,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Media selection buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _pickMedia(ImageSource.gallery),
                    ),
                    _buildControlButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _pickMedia(ImageSource.camera),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController!.value.size.width,
        height: _videoController!.value.size.height,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Image.file(
      _mediaFile!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      // Show media type selection
      final mediaType = await _showMediaTypeDialog();
      if (mediaType == null) {
        setState(() => _isLoading = false);
        return;
      }

      XFile? pickedFile;
      if (mediaType == 'photo') {
        pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1920,
          imageQuality: 85,
        );
        _isVideo = false;
      } else {
        pickedFile = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 30),
        );
        _isVideo = true;
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
        });

        if (_isVideo) {
          await _initializeVideoPlayer();
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      _showErrorSnackBar('Failed to pick media');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showMediaTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Select Media Type',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
              title: Text(
                'Photo',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              onTap: () => Navigator.pop(context, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.white),
              title: Text(
                'Video',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeVideoPlayer() async {
    if (_mediaFile != null && _isVideo) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_mediaFile!);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      setState(() {});
    }
  }

  Future<void> _cropImage() async {
    if (_mediaFile == null || _isVideo) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _mediaFile!.path,
        aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _mediaFile = File(croppedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      _showErrorSnackBar('Failed to crop image');
    }
  }

  void _showTextEditor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildTextEditorBottomSheet(),
    );
  }

  Widget _buildTextEditorBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: EdgeInsets.all(16.w),
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
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Text input
          TextField(
            controller: _textController,
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: 'Enter your text...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
            maxLines: 3,
          ),

          SizedBox(height: 16.h),

          // Text size slider
          Row(
            children: [
              Text(
                'Size:',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
              Expanded(
                child: Slider(
                  value: _textSize,
                  min: 12.0,
                  max: 48.0,
                  divisions: 36,
                  activeColor: Colors.blue,
                  onChanged: (value) {
                    setState(() {
                      _textSize = value;
                    });
                  },
                ),
              ),
              Text(
                '${_textSize.round()}',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ],
          ),

          // Color picker
          SizedBox(height: 16.h),
          Text(
            'Text Color:',
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Colors.white,
              Colors.black,
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.purple,
              Colors.orange,
            ].map((color) => _buildColorOption(color)).toList(),
          ),

          SizedBox(height: 24.h),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _overlayText = _textController.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Apply Text',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _textColor = color;
        });
      },
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _textColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _showAudioSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Select Audio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            ListTile(
              leading: const Icon(Icons.music_note, color: Colors.white),
              title: Text(
                'Original Audio',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Original audio selected');
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music, color: Colors.white),
              title: Text(
                'Music Library',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Music library - Coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.white),
              title: Text(
                'Record Audio',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Audio recording - Coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 200.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Filters and effects coming soon!',
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  void _uploadStory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Upload Story',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          'Your story is ready to upload!\n\n(Upload functionality will be implemented in the future)',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close story screen
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.blue, fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
