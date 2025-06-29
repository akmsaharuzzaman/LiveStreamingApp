import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final ImagePicker _picker = ImagePicker();
  VideoEditorController? videoEditorController;
  VideoPlayerController? videoPlayerController;
  bool canShowEditor = false;
  List<String> trimVideos = []; // Non-nullable list
  bool isSeeking = false;
  String? audioPath;
  Duration? audioTrimStart;
  Duration? audioTrimEnd;
  bool _isUploading = false;

  @override
  void dispose() {
    videoEditorController?.dispose();
    videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) return;

      videoEditorController = VideoEditorController.file(
        File(file.path),
        maxDuration: const Duration(seconds: 59),
        minDuration: const Duration(seconds: 1),
      );
      videoPlayerController = VideoPlayerController.file(File(file.path));

      await Future.wait([
        videoEditorController!.initialize(),
        videoPlayerController!.initialize(),
      ]);

      videoPlayerController!.addListener(() {
        if (!mounted || isSeeking) return;
        final position = videoPlayerController!.value.position;
        final endTrim = videoEditorController!.endTrim;
        if (position >= endTrim) {
          videoPlayerController!.pause();
          videoPlayerController!.seekTo(videoEditorController!.startTrim);
        }
        setState(() {});
      });

      setState(() {
        canShowEditor = true;
      });
    } catch (e) {
      log("Pick Video Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load video")));
      }
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result == null || result.files.single.path == null || !mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No audio file selected")));
        return;
      }

      setState(() {
        audioPath = result.files.single.path!;
        audioTrimStart = Duration.zero;
        audioTrimEnd = videoEditorController?.endTrim ?? Duration.zero;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Audio added: ${path.basename(audioPath!)}")),
      );
    } catch (e) {
      log("Pick Audio Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to pick audio: $e")));
      }
    }
  }

  void _cropAudio() {
    if (audioPath == null || videoEditorController == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No audio or video selected")),
      );
      return;
    }
    setState(() {
      audioTrimStart = Duration.zero;
      audioTrimEnd = videoEditorController!.endTrim;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Audio cropped to video duration")),
    );
  }

  Future<void> _trimVideo() async {
    if (videoEditorController == null || !mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No video selected")));
      return;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
      final String filename = 'trimmed_video_$timestamp.mp4';
      final String outputPath = path.join(tempDir.path, filename);

      final String? result = await EasyVideoEditorPlatform.instance.trimVideo(
        videoEditorController!.file.path,
        videoEditorController!.startTrim.inMilliseconds,
        videoEditorController!.endTrim.inMilliseconds,
      );

      if (result != null && mounted) {
        setState(() {
          trimVideos.add(result);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Video exported to: $outputPath")),
        );
      } else {
        throw Exception("Trimming failed");
      }
    } catch (e) {
      log("Trim Video Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to trim video")));
      }
    }
  }

  Future<void> _uploadReel(String videoPath, int videoLength) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Authentication token is missing. Please log in again.',
            ),
          ),
        );
      }
      setState(() {
        _isUploading = false;
      });
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final url = Uri.parse('http://dlstarlive.com:8000/api/reels/create');
    final request = http.MultipartRequest('POST', url);

    // Set headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields
    request.fields['video_length'] = videoLength.toString();

    // Add video file
    final file = File(videoPath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video file not found.')));
      }
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      final multipartFile = await http.MultipartFile.fromPath(
        'video',
        videoPath,
        contentType: MediaType('video', 'mp4'),
      );
      request.files.add(multipartFile);

      // Send request
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      final responseJson = jsonDecode(responseString);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        if (responseJson['success'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reel uploaded successfully!')),
          );
          context.go('/newsfeed');
        } else {
          throw Exception(responseJson['message'] ?? 'Upload failed');
        }
      } else {
        throw Exception(
          responseJson['message'] ??
              'Failed to upload. Status code: \\${response.statusCode}',
        );
      }
    } catch (e) {
      log('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('either wrong reel Id')
                  ? 'Invalid reel data. Please try again.'
                  : 'Upload failed: \\${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _mergeAndUpload() async {
    setState(() {
      _isUploading = true;
    });
    String? resultPath;
    try {
      if (trimVideos.isEmpty || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No trimmed videos to merge")),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }
      if (audioPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Audio merging not implemented (requires FFmpeg)"),
          ),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }
      resultPath = await EasyVideoEditorPlatform.instance.mergeVideos(
        trimVideos,
      );
      if (resultPath == null) throw Exception('Merging failed');
      final videoFile = File(resultPath);
      final videoLength = await videoFile.exists()
          ? (await VideoPlayerController.file(videoFile).initialize().then(
              (c) => VideoPlayerController.file(
                videoFile,
              ).value.duration.inSeconds,
            ))
          : 0;
      await _uploadReel(resultPath, videoLength);
    } catch (e) {
      log('Merge & Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Merge/Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Video Editor',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (canShowEditor &&
              videoPlayerController != null &&
              videoPlayerController!.value.isInitialized &&
              videoEditorController != null &&
              videoEditorController!.initialized) ...[
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio:
                              videoPlayerController!.value.aspectRatio > 0
                              ? videoPlayerController!.value.aspectRatio
                              : 16 / 9,
                          child: VideoPlayer(videoPlayerController!),
                        ),
                        IconButton(
                          onPressed: () {
                            if (!mounted) return;
                            setState(() {
                              if (videoPlayerController!.value.isPlaying) {
                                videoPlayerController!.pause();
                              } else {
                                final trimStart =
                                    videoEditorController!.startTrim;
                                final trimEnd = videoEditorController!.endTrim;
                                final pos =
                                    videoPlayerController!.value.position;
                                if (pos < trimStart || pos >= trimEnd) {
                                  videoPlayerController!.seekTo(trimStart);
                                }
                                videoPlayerController!.play();
                              }
                            });
                          },
                          icon: Icon(
                            videoPlayerController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 45.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (videoEditorController != null)
                    Builder(
                      builder: (context) {
                        final trimStart = videoEditorController!.startTrim;
                        final trimEnd = videoEditorController!.endTrim;
                        final duration = trimEnd - trimStart;
                        final position = videoPlayerController!.value.position;
                        final sliderValue = position < trimStart
                            ? 0.0
                            : (position >= trimEnd
                                  ? duration.inMilliseconds.toDouble()
                                  : (position - trimStart).inMilliseconds
                                        .toDouble());
                        return Slider(
                          value: sliderValue,
                          min: 0.0,
                          max: duration.inMilliseconds.toDouble(),
                          onChangeStart: (value) {
                            isSeeking = true;
                            videoPlayerController!.pause();
                          },
                          onChanged: (value) {
                            final seekTo =
                                trimStart +
                                Duration(milliseconds: value.toInt());
                            videoPlayerController!.seekTo(seekTo);
                            setState(() {});
                          },
                          onChangeEnd: (value) {
                            isSeeking = false;
                            videoPlayerController!.play();
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trimVideos.length,
                onReorder: (int oldIndex, int newIndex) {
                  if (!mounted) return;
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final movedClip = trimVideos.removeAt(oldIndex);
                    trimVideos.insert(newIndex, movedClip);
                  });
                },
                itemBuilder: (context, index) {
                  return ReorderableDragStartListener(
                    index: index,
                    key: ValueKey(trimVideos[index]),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[800],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 40.sp,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  trimVideos.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (videoEditorController != null)
              Padding(
                padding: const EdgeInsets.only(right: 22.0),
                child: TrimSlider(
                  controller: videoEditorController!,
                  height: 60.sp,
                  horizontalMargin: 15.sp,
                  child: TrimTimeline(controller: videoEditorController!),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                top: 10.sp,
                right: 20.sp,
                left: 20.sp,
                bottom: 8.sp,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _trimVideo,
                    child: const Icon(Icons.content_cut, color: Colors.white),
                  ),
                  const Icon(
                    Icons.crop,
                    color: Colors.white,
                  ), // Placeholder for crop functionality
                  const Icon(
                    Icons.speed,
                    color: Colors.white,
                  ), // Placeholder for speed functionality
                  GestureDetector(
                    onTap: _pickAudio,
                    child: Icon(
                      Icons.music_note,
                      color: audioPath != null ? Colors.green : Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: _cropAudio,
                    child: Icon(
                      Icons.cut,
                      color: audioPath != null ? Colors.orange : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.sp),
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                      onPressed: _mergeAndUpload,
                      child: Text(
                        "Merge & Export Final Video and Upload",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Text(
                  "Select a video to start editing",
                  style: TextStyle(color: Colors.white, fontSize: 18.sp),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 15.sp,
                right: 15.sp,
                bottom: 50.sp,
              ),
              child: SizedBox(
                height: 40.h,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      const Color(0xff2c3968),
                    ),
                  ),
                  onPressed: _pickVideo,
                  child: Text(
                    "Import Video",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
