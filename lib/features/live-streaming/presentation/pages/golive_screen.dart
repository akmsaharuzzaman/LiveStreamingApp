import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:streaming_djlive/features/core/services/navbar_provider.dart';
import 'package:streaming_djlive/features/live-streaming/data/models/live_stream.dart';
import 'package:streaming_djlive/features/live-streaming/presentation/pages/live_streaming_screen.dart';

class GoliveScreen extends StatefulWidget {
  const GoliveScreen({super.key});

  @override
  State<GoliveScreen> createState() => _GoliveScreenState();
}

class _GoliveScreenState extends State<GoliveScreen> {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  // final StorageService _storageService = StorageService();
  bool _isLoading = false;
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _goLive() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a thumbnail first')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a stream title')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // final authState = context.read<AuthCubit>().state;
      if (true /* authState is Authenticated */ ) {
        // Generate unique stream ID
        final streamId = 'stream_${DateTime.now().millisecondsSinceEpoch}';

        // Upload thumbnail to Firebase Storage
        // String? thumbnailUrl = await _firestoreService.uploadliveStreamThumnail(
        //   streamId: streamId,
        //   filePath: _selectedImage!,
        // );

        // ignore: unnecessary_null_comparison
        if (true) {
          // Create live stream document in Firestore
          final liveStream = LiveStream(
            id: streamId,
            title: _titleController.text.trim(),
            thumbnailUrl: '', // thumbnailUrl ?? '',
            channelId: streamId, // Using same ID for channel
            userId: '',
            userName: 'Anonymous',
            userProfilePic: '',
            startTime: DateTime.now(),
            isLive: true,
            viewerCount: 0,
            tags: [], // Could add tag selection in UI later
            liveType: LiveType.live,
            countryCode: 'BD',
          );

          // await _firestoreService.createLiveStream(liveStream);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Live stream started successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Navigate to live streaming screen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LiveStreamingScreen(
                  streamId: streamId,
                  title: _titleController.text.trim(),
                  thumbnailPath: _selectedImage!.path,
                  isBroadCaster: true,
                  userName: 'Anonymous',
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload thumbnail'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to go live')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Go Live'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Set up your live stream',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a thumbnail and title for your stream',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Thumbnail Selection
            const Text(
              'Thumbnail',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImageFromGallery,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to select thumbnail',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose from gallery',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),

            // Stream Title
            const Text(
              'Stream Title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'Enter your stream title...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 40), // Go Live Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _goLive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_fill, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'GO LIVE NOW',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Tips Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for a great stream',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Choose an eye-catching thumbnail\n'
                    '• Write a descriptive title\n'
                    '• Make sure you have good lighting\n'
                    '• Test your internet connection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
